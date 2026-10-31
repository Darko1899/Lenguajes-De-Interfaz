; =====================================================================
;  VentasInventario.asm
;  Lenguajes de Interfaz - Unidad 2
;  Proyecto: sistema de ventas e inventario en consola
;  Plataforma: MASM x86 (32 bits) + biblioteca Irvine32
;  Negocio   : ByteShop, tienda de accesorios electronicos
;  Regla extra: descuento por cantidad (10% si se venden 10 o mas
;               unidades de un mismo producto en una venta)
; ---------------------------------------------------------------------
;  CONVENCION DE PROCEDIMIENTOS DE ESTE PROGRAMA
;   * Cada procedimiento documenta Entrada, Salida y Registros.
;   * Un procedimiento conserva TODOS los registros que no aparezcan
;     como "Salida". Los pequenos usan PUSH/POP de los registros que
;     tocan; los grandes usan PUSHAD/POPAD al entrar y salir.
;   * Cada PUSH tiene su POP: la pila queda equilibrada al hacer RET.
;   * Los recorridos de cadenas y de la tabla de productos usan ESI.
;   * Todos los importes se guardan como CENTAVOS enteros (DWORD).
;   * Los mensajes no llevan acentos para evitar problemas de codigo
;     de pagina en la consola de Windows.
; =====================================================================
INCLUDE Irvine32.inc

; ---------------------------------------------------------------------
; CONSTANTES
; ---------------------------------------------------------------------
MAX_PRODUCTS  EQU 10          ; capacidad del catalogo
MAX_NAME      EQU 25          ; caracteres maximos del nombre
MAX_STOCK     EQU 100         ; existencia maxima por producto
MAX_PRICE     EQU 999999      ; $9999.99 en centavos

; Estructura de un registro de producto (44 bytes)
;   +0  codigo   8 bytes  "ABC-123",0
;   +8  nombre  26 bytes  hasta 25 caracteres + 0
;   +34 relleno  2 bytes  (alinea los DWORD)
;   +36 precio   DWORD    centavos
;   +40 existencia DWORD  unidades
REC_SIZE      EQU 44
OFF_CODE      EQU 0
OFF_NAME      EQU 8
OFF_PRICE     EQU 36
OFF_STOCK     EQU 40

; Regla del negocio: descuento por cantidad
DISC_MIN_QTY  EQU 10          ; unidades minimas para aplicar
DISC_PERCENT  EQU 10          ; porcentaje de descuento

IN_MAX        EQU 100         ; caracteres maximos que lee ReadString
FIELD_MAX     EQU 60          ; longitud maxima de un campo del archivo
FILE_CAP      EQU 1024        ; bytes que se leen del archivo como maximo

; ---------------------------------------------------------------------
; DATOS
; ---------------------------------------------------------------------
.data
ALIGN 4
catalog       BYTE MAX_PRODUCTS*REC_SIZE DUP(0)   ; catalogo en uso
tmpCatalog    BYTE MAX_PRODUCTS*REC_SIZE DUP(0)   ; catalogo temporal (carga)
newRec        BYTE REC_SIZE DUP(0)                ; registro en preparacion
prodCount     DWORD 0                             ; productos registrados
sessionIncome DWORD 0                             ; ingresos de la sesion (centavos)
sessionDisc   DWORD 0                             ; descuentos de la sesion (centavos)
saleBase      DWORD 0                             ; resultado de ComputeSale
saleDisc      DWORD 0
saleFinal     DWORD 0
hFile         DWORD 0                             ; handle de archivo
fileBytes     DWORD 0                             ; bytes leidos / escritos
saveLen       DWORD 0                             ; bytes que se desean guardar
ldText        DWORD 0                             ; puntero de lectura del archivo
ldCount       DWORD 0                             ; productos declarados en el archivo
testEsp       DWORD 0                             ; ESP de referencia (prueba interna)
testFail      DWORD 0                             ; verificaciones fallidas
dirty         BYTE 0                              ; 1 = hay cambios sin guardar

inBuf         BYTE 128 DUP(0)                     ; buffer de ReadString
fieldBuf      BYTE 64 DUP(0)                      ; campo extraido del archivo
numBuf        BYTE 16 DUP(0)                      ; numero convertido a texto
moneyBuf      BYTE 32 DUP(0)                      ; importe formateado
curFile       BYTE 128 DUP(0)                     ; archivo de trabajo
prevFile      BYTE 128 DUP(0)                     ; copia del nombre anterior
fileBuf       BYTE FILE_CAP+1 DUP(0)              ; +1 reservado para el 00h final

defaultFile   BYTE "inventario.txt",0
fileMagic     BYTE "INVENTARIO-MASM-V1",0
strCRLF       BYTE 0Dh,0Ah,0
testPrice     BYTE "185.50",0

; ---- mensajes ----
msgBanner     BYTE 0Dh,0Ah,"=====================================================",0Dh,0Ah,
                   "  ByteShop - Ventas e inventario (MASM x86 / Irvine32)",0Dh,0Ah,
                   "=====================================================",0Dh,0Ah,0
msgAutoLoad   BYTE "Buscando inventario.txt para recuperar el catalogo...",0Dh,0Ah,0
msgMenu       BYTE 0Dh,0Ah,"------------------- MENU -------------------",0Dh,0Ah,
                   " 1. Registrar producto",0Dh,0Ah,
                   " 2. Mostrar inventario",0Dh,0Ah,
                   " 3. Buscar producto por codigo",0Dh,0Ah,
                   " 4. Recibir mercancia",0Dh,0Ah,
                   " 5. Vender",0Dh,0Ah,
                   " 6. Resumen",0Dh,0Ah,
                   " 7. Cotizar venta (regla de descuento)",0Dh,0Ah,
                   " 8. Guardar inventario en archivo",0Dh,0Ah,
                   " 9. Cargar inventario desde archivo",0Dh,0Ah,
                   " T. Prueba interna de pila y registros",0Dh,0Ah,
                   " 0. Salir",0Dh,0Ah,
                   "Opcion: ",0
msgBadOption  BYTE "Opcion no valida.",0Dh,0Ah,0
msgCancelled  BYTE "Operacion cancelada. No se modifico nada.",0Dh,0Ah,0

msgAskCode    BYTE "Codigo (formato ABC-123): ",0
msgAskName    BYTE "Nombre (1 a 25 caracteres): ",0
msgAskPrice   BYTE "Precio en MXN (0.01 a 9999.99, ej. 185.50): ",0
msgAskStock   BYTE "Existencia inicial (0 a 100): ",0
msgAskQtyIn   BYTE "Unidades a recibir: ",0
msgAskQtySell BYTE "Unidades a vender: ",0
msgAskQtyQuote BYTE "Unidades a cotizar: ",0
msgAskFile    BYTE "Archivo (Enter = inventario.txt): ",0

msgBadCode    BYTE "ERROR: codigo invalido. Use 3 letras mayusculas, guion y 3 digitos (ej. ABC-123).",0Dh,0Ah,0
msgDup        BYTE "ERROR: ya existe un producto con ese codigo. No se modifico nada.",0Dh,0Ah,0
msgFull       BYTE "ERROR: catalogo lleno (maximo 10 productos). No se modifico nada.",0Dh,0Ah,0
msgBadName    BYTE "ERROR: nombre invalido (1 a 25 caracteres, sin el simbolo | ni teclas de control).",0Dh,0Ah,0
msgBadPrice   BYTE "ERROR: precio invalido. Use pesos enteros o punto con 1 o 2 decimales, de 0.01 a 9999.99 (sin $ ni comas).",0Dh,0Ah,0
msgBadStock   BYTE "ERROR: existencia invalida (entero de 0 a 100).",0Dh,0Ah,0
msgBadQty     BYTE "ERROR: cantidad invalida (entero mayor que cero, solo digitos).",0Dh,0Ah,0
msgNotFound   BYTE "ERROR: no existe un producto con ese codigo.",0Dh,0Ah,0
msgNoStock    BYTE "ERROR: existencias insuficientes. Venta rechazada; no se modifico nada.",0Dh,0Ah,0
msgOverStock  BYTE "ERROR: la entrada superaria el maximo de 100 unidades. No se modifico nada.",0Dh,0Ah,0
msgOvf        BYTE "ERROR: desbordamiento en el calculo. Operacion rechazada; no se modifico nada.",0Dh,0Ah,0

msgRegOk      BYTE "Producto registrado correctamente.",0Dh,0Ah,0
msgRecvOk     BYTE "Mercancia recibida. Nueva existencia: ",0
msgEmpty      BYTE "El inventario esta vacio.",0Dh,0Ah,0
msgSaleOk     BYTE "Venta registrada.",0Dh,0Ah,0
msgQuote      BYTE "Cotizacion (no modifica existencias ni ingresos):",0Dh,0Ah,0
msgNoDisc     BYTE "Descuento por cantidad: no aplica (se requieren 10 o mas unidades).",0Dh,0Ah,0

msgInvHeader  BYTE "CODIGO    NOMBRE                      PRECIO            EXIST.",0Dh,0Ah,
                   "---------------------------------------------------------------",0Dh,0Ah,0
msgFound      BYTE "Producto encontrado:",0Dh,0Ah,0
lblCode       BYTE "  Codigo     : ",0
lblName       BYTE "  Nombre     : ",0
lblPrice      BYTE "  Precio     : ",0
lblStock      BYTE "  Existencia : ",0
lblValue      BYTE "  Valor en inventario: ",0
lblProduct    BYTE "Producto: ",0
lblQty        BYTE "Cantidad: ",0
lblBase       BYTE "Importe base: ",0
lblDisc       BYTE "Descuento por cantidad (10%): -",0
lblTotal      BYTE "Total a cobrar: ",0
lblRemain     BYTE "Existencia restante: ",0

msgSumTitle   BYTE 0Dh,0Ah,"------------------ RESUMEN ------------------",0Dh,0Ah,0
lblSumProds   BYTE "Productos registrados          : ",0
lblSumUnits   BYTE "Unidades disponibles           : ",0
lblSumValue   BYTE "Valor total del inventario     : ",0
lblSumIncome  BYTE "Ingresos acumulados (sesion)   : ",0
lblSumDisc    BYTE "Descuentos otorgados (sesion)  : ",0
msgRule       BYTE "Regla: 10% de descuento si una venta lleva 10 o mas unidades del mismo producto.",0Dh,0Ah,0

msgLoadNoFile BYTE "No se pudo abrir el archivo (no existe o no es accesible). Catalogo sin cambios.",0Dh,0Ah,0
msgLoadReadErr BYTE "ERROR de lectura del archivo. Catalogo sin cambios.",0Dh,0Ah,0
msgLoadBig    BYTE "ERROR: archivo demasiado grande (maximo 1023 bytes). Catalogo sin cambios.",0Dh,0Ah,0
msgLoadHeader BYTE "ERROR: encabezado invalido; no es un archivo de inventario. Catalogo sin cambios.",0Dh,0Ah,0
msgLoadFormat BYTE "ERROR: estructura danada (faltan campos o sobran datos). Catalogo sin cambios.",0Dh,0Ah,0
msgLoadCount  BYTE "ERROR: la cantidad de productos del archivo debe estar entre 0 y 10. Catalogo sin cambios.",0Dh,0Ah,0
msgLoadRec    BYTE "ERROR: datos invalidos o repetidos en el registro #",0
msgLoadRec2   BYTE ". Catalogo sin cambios.",0Dh,0Ah,0
msgLoadOk     BYTE "Catalogo cargado correctamente. Productos: ",0
msgLoadDirty  BYTE "Hay cambios sin guardar; cargar un archivo los reemplazara. Continuar? (S/N): ",0
msgSaveOk     BYTE "Inventario guardado. Bytes escritos: ",0
msgSaveErrOpen BYTE "ERROR: no se pudo crear el archivo. Los datos siguen en memoria.",0Dh,0Ah,0
msgSaveErrWr  BYTE "ERROR: escritura incompleta o fallida. Los datos siguen en memoria.",0Dh,0Ah,0
msgDirtyExit  BYTE "Hay cambios sin guardar. S = guardar y salir, N = salir sin guardar, otra tecla = cancelar: ",0

msgSelfTitle  BYTE 0Dh,0Ah,"--- Prueba interna: registros y pila ---",0Dh,0Ah,
                   "Se cargan EBX, ECX, EDX, ESI y EDI con valores conocidos, se llaman 7 procedimientos",0Dh,0Ah,
                   "y despues de cada CALL se compara ESP y los registros.",0Dh,0Ah,0
msgSelfMoney  BYTE "Formato de 1205 centavos: ",0
msgSelfOk     BYTE "RESULTADO: pila equilibrada y registros conservados (0 fallas).",0Dh,0Ah,0
msgSelfBad    BYTE "RESULTADO: FALLA. Verificaciones incorrectas: ",0

; ---------------------------------------------------------------------
; CODIGO
; ---------------------------------------------------------------------
.code

;=====================================================================
;  UTILIDADES DE CADENAS
;=====================================================================

;---------------------------------------------------------------------
; StrLen - longitud de una cadena terminada en 0
; Entrada : ESI = direccion de la cadena
; Salida  : EAX = numero de caracteres (sin contar el 00h)
; Modifica: EAX, flags. Conserva ESI y los demas registros.
;---------------------------------------------------------------------
StrLen PROC
    push esi
    xor eax, eax
SLN_loop:
    cmp BYTE PTR [esi], 0
    je SLN_end
    inc eax
    inc esi
    jmp SLN_loop
SLN_end:
    pop esi
    ret
StrLen ENDP

;---------------------------------------------------------------------
; StrCopy - copia una cadena incluyendo el 00h final
; Entrada : ESI = origen, EDI = destino (con espacio suficiente)
; Salida  : ninguna
; Modifica: flags. Conserva todos los registros.
;---------------------------------------------------------------------
StrCopy PROC
    push eax
    push esi
    push edi
SCP_loop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    test al, al
    jnz SCP_loop
    pop edi
    pop esi
    pop eax
    ret
StrCopy ENDP

;---------------------------------------------------------------------
; StrEq - compara dos cadenas terminadas en 0
; Entrada : ESI = cadena 1, EDI = cadena 2
; Salida  : ZF = 1 si son iguales, ZF = 0 si son distintas
; Modifica: flags. Conserva todos los registros.
;---------------------------------------------------------------------
StrEq PROC
    push eax
    push esi
    push edi
SEQ_loop:
    mov al, [esi]
    cmp al, [edi]
    jne SEQ_end              ; distintas: ZF = 0
    test al, al              ; ambas terminaron: ZF = 1
    jz SEQ_end
    inc esi
    inc edi
    jmp SEQ_loop
SEQ_end:
    pop edi
    pop esi
    pop eax
    ret
StrEq ENDP

;---------------------------------------------------------------------
; AppendStr - agrega una cadena (sin su 00h) al final de un buffer
; Entrada : EDX = cadena origen, EDI = posicion de escritura
; Salida  : EDI avanza hasta la posicion siguiente al ultimo caracter
; Modifica: EDI, flags. Conserva EAX, EDX y los demas.
;---------------------------------------------------------------------
AppendStr PROC
    push eax
    push edx
APS_loop:
    mov al, [edx]
    test al, al
    jz APS_end
    mov [edi], al
    inc edx
    inc edi
    jmp APS_loop
APS_end:
    pop edx
    pop eax
    ret
AppendStr ENDP

;---------------------------------------------------------------------
; RemoveCR - elimina todos los 0Dh de un texto (CRLF pasa a LF)
; Entrada : ESI = texto terminado en 00h (se modifica en sitio)
; Salida  : el mismo buffer, compactado
; Modifica: memoria del buffer, flags. Conserva todos los registros.
;---------------------------------------------------------------------
RemoveCR PROC
    push eax
    push esi
    push edi
    mov edi, esi                ; EDI escribe, ESI lee
RCR_loop:
    mov al, [esi]
    inc esi
    cmp al, 0Dh
    je RCR_loop                 ; se omite el retorno de carro
    mov [edi], al
    inc edi
    test al, al
    jnz RCR_loop
    pop edi
    pop esi
    pop eax
    ret
RemoveCR ENDP

;=====================================================================
;  CONVERSIONES NUMERICAS PROPIAS (sin ReadDec/WriteDec/Parse...)
;=====================================================================

;---------------------------------------------------------------------
; ParseUInt - convierte una cadena de digitos a entero sin signo
; Entrada : ESI = cadena terminada en 00h
; Salida  : CF = 0 -> EAX = valor
;           CF = 1 -> cadena vacia, caracter no digito o desborde (EAX = 0)
; Modifica: EAX, flags. Conserva EBX, ECX, EDX, ESI, EDI.
;---------------------------------------------------------------------
ParseUInt PROC
    push ebx
    push ecx
    push edx
    push esi
    xor eax, eax                ; acumulador
    xor ecx, ecx                ; cuenta de digitos leidos
PUI_loop:
    movzx ebx, BYTE PTR [esi]
    test bl, bl
    jz PUI_end                  ; fin de la cadena
    cmp bl, '0'
    jb PUI_bad
    cmp bl, '9'
    ja PUI_bad
    sub ebx, '0'                ; ASCII -> valor 0..9
    mov edx, 10
    mul edx                     ; EDX:EAX = EAX * 10 ; CF=1 si EDX <> 0
    jc PUI_bad
    add eax, ebx
    jc PUI_bad
    inc ecx
    inc esi
    jmp PUI_loop
PUI_end:
    test ecx, ecx               ; cadena vacia -> error
    jz PUI_bad
    clc
    jmp PUI_out
PUI_bad:
    xor eax, eax
    stc
PUI_out:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
ParseUInt ENDP

;---------------------------------------------------------------------
; ParsePrice - convierte "185.50", "12.05", "90", "7.5" a centavos
;   Acepta: digitos [ "." 1 o 2 digitos ]. Rechaza simbolos, comas,
;   tercer decimal, "0.00" y valores fuera de 0.01 a 9999.99.
; Entrada : ESI = cadena terminada en 00h
; Salida  : CF = 0 -> EAX = centavos (1..999999)
;           CF = 1 -> precio invalido (EAX = 0)
; Modifica: EAX, flags. Conserva EBX, ECX, EDX, ESI, EDI.
;---------------------------------------------------------------------
ParsePrice PROC
    push ebx
    push ecx
    push edx
    push esi
    xor eax, eax                ; EAX = pesos
    xor ecx, ecx                ; ECX = digitos de la parte entera
PPR_int:
    movzx ebx, BYTE PTR [esi]
    cmp bl, '0'
    jb PPR_endInt
    cmp bl, '9'
    ja PPR_endInt
    sub ebx, '0'
    lea eax, [eax+eax*4]        ; EAX * 5
    add eax, eax                ; * 2  -> EAX * 10
    add eax, ebx
    cmp eax, 9999               ; fuera de rango (tambien evita desborde)
    ja PPR_bad
    inc ecx
    inc esi
    jmp PPR_int
PPR_endInt:
    test ecx, ecx               ; debe haber al menos un digito entero
    jz PPR_bad
    imul eax, eax, 100          ; pesos -> centavos
    movzx ebx, BYTE PTR [esi]
    test bl, bl
    jz PPR_check                ; entero sin punto: "90"
    cmp bl, '.'
    jne PPR_bad                 ; coma, $, letra, espacio...
    inc esi
    movzx ebx, BYTE PTR [esi]   ; primer decimal (obligatorio)
    cmp bl, '0'
    jb PPR_bad
    cmp bl, '9'
    ja PPR_bad
    sub ebx, '0'
    lea edx, [ebx+ebx*4]
    add edx, edx                ; EDX = decimas * 10 (decenas de centavo)
    add eax, edx
    inc esi
    movzx ebx, BYTE PTR [esi]   ; segundo decimal (opcional)
    test bl, bl
    jz PPR_check
    cmp bl, '0'
    jb PPR_bad
    cmp bl, '9'
    ja PPR_bad
    sub ebx, '0'
    add eax, ebx
    inc esi
    cmp BYTE PTR [esi], 0       ; un tercer decimal o basura se rechaza
    jne PPR_bad
PPR_check:
    test eax, eax               ; 0.00 no es valido
    jz PPR_bad
    clc
    jmp PPR_out
PPR_bad:
    xor eax, eax
    stc
PPR_out:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
ParsePrice ENDP

;---------------------------------------------------------------------
; UIntToStr - entero sin signo -> cadena decimal ASCII
;   Divide entre 10: el residuo es el digito (se apila) y el cociente
;   se vuelve a dividir. Al desapilar salen en el orden correcto.
; Entrada : EAX = valor, EDI = buffer destino (minimo 11 bytes)
; Salida  : [EDI] = cadena terminada en 00h ; EAX = numero de digitos
; Modifica: EAX, flags. Conserva EBX, ECX, EDX, EDI.
;---------------------------------------------------------------------
UIntToStr PROC
    push ebx
    push ecx
    push edx
    push edi
    mov ebx, 10
    xor ecx, ecx                ; ECX = cantidad de digitos
U2S_div:
    xor edx, edx                ; parte alta del dividendo = 0
    div ebx                     ; EAX = cociente, EDX = residuo (0..9)
    push edx                    ; guardar el digito
    inc ecx
    test eax, eax
    jnz U2S_div
    mov eax, ecx                ; EAX = longitud
U2S_out:
    pop edx                     ; sale primero el digito mas significativo
    add dl, '0'                 ; valor 0..9 -> ASCII '0'..'9'
    mov [edi], dl
    inc edi
    dec ecx
    jnz U2S_out
    mov BYTE PTR [edi], 0
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret
UIntToStr ENDP

;---------------------------------------------------------------------
; FormatMoney - centavos -> "$pesos.cc MXN"
;   Separa con DIV entre 100: cociente = pesos, residuo = centavos.
;   Si los centavos son menores que 10 se antepone un '0' (5 -> "05").
; Entrada : EAX = importe en centavos, EDI = buffer destino (min. 24 bytes)
; Salida  : [EDI] = cadena terminada en 00h
; Modifica: memoria del buffer, flags. Conserva todos los registros.
;---------------------------------------------------------------------
FormatMoney PROC
    push eax
    push ebx
    push ecx
    push edx
    push edi
    mov BYTE PTR [edi], '$'
    inc edi
    xor edx, edx
    mov ebx, 100
    div ebx                     ; EAX = pesos, EDX = centavos
    mov ecx, edx                ; ECX = centavos
    call UIntToStr              ; escribe los pesos; EAX = digitos
    add edi, eax
    mov BYTE PTR [edi], '.'
    inc edi
    cmp ecx, 10
    jae FMM_two
    mov BYTE PTR [edi], '0'     ; relleno: 5 -> "05"
    inc edi
FMM_two:
    mov eax, ecx
    call UIntToStr
    add edi, eax
    mov BYTE PTR [edi], ' '
    mov BYTE PTR [edi+1], 'M'
    mov BYTE PTR [edi+2], 'X'
    mov BYTE PTR [edi+3], 'N'
    mov BYTE PTR [edi+4], 0
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
FormatMoney ENDP

;=====================================================================
;  SALIDA DE TEXTO (todo con WriteString / WriteChar)
;=====================================================================

;---------------------------------------------------------------------
; PrintUInt - muestra un entero sin signo
; Entrada : EAX = valor
; Salida  : texto en consola
; Modifica: flags. Conserva todos los registros.
;---------------------------------------------------------------------
PrintUInt PROC
    push eax
    push edx
    push edi
    mov edi, OFFSET numBuf
    call UIntToStr
    mov edx, OFFSET numBuf
    call WriteString
    pop edi
    pop edx
    pop eax
    ret
PrintUInt ENDP

;---------------------------------------------------------------------
; PrintMoney - muestra un importe como "$1250.00 MXN"
; Entrada : EAX = centavos
; Salida  : texto en consola
; Modifica: flags. Conserva todos los registros.
;---------------------------------------------------------------------
PrintMoney PROC
    push edx
    push edi
    mov edi, OFFSET moneyBuf
    call FormatMoney
    mov edx, OFFSET moneyBuf
    call WriteString
    pop edi
    pop edx
    ret
PrintMoney ENDP

;---------------------------------------------------------------------
; PrintLabelMoney / PrintLabelUInt - etiqueta + valor + salto de linea
; Entrada : EDX = etiqueta (cadena), EAX = centavos / valor
; Modifica: flags. Conserva todos los registros.
;---------------------------------------------------------------------
PrintLabelMoney PROC
    call WriteString
    call PrintMoney
    call Crlf
    ret
PrintLabelMoney ENDP

PrintLabelUInt PROC
    call WriteString
    call PrintUInt
    call Crlf
    ret
PrintLabelUInt ENDP

;---------------------------------------------------------------------
; WriteStrPad - escribe una cadena y la rellena con espacios
; Entrada : EDX = cadena, ECX = ancho de la columna
; Modifica: flags. Conserva todos los registros.
;---------------------------------------------------------------------
WriteStrPad PROC
    push eax
    push ecx
    push esi
    mov esi, edx
    call StrLen                 ; EAX = longitud
    call WriteString
    sub ecx, eax                ; espacios que faltan
    jbe WSP_end                 ; si ya ocupa el ancho, no se rellena
WSP_pad:
    mov al, ' '
    call WriteChar
    dec ecx
    jnz WSP_pad
WSP_end:
    pop esi
    pop ecx
    pop eax
    ret
WriteStrPad ENDP

;=====================================================================
;  CAPTURA Y VALIDACION
;=====================================================================

;---------------------------------------------------------------------
; ReadLine - captura una linea con ReadString
;   Antes de ReadString: EDX = OFFSET inBuf (donde se guarda el texto)
;                        ECX = IN_MAX (maximo de caracteres)
;   Al regresar ReadString: EAX = caracteres capturados; el texto queda
;   en inBuf terminado en 00h.
; Entrada : ninguna
; Salida  : EAX = longitud, inBuf = texto
; Modifica: EAX, flags. Conserva EBX, ECX, EDX, ESI, EDI.
;---------------------------------------------------------------------
ReadLine PROC
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov edx, OFFSET inBuf
    mov ecx, IN_MAX
    call ReadString
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
ReadLine ENDP

;---------------------------------------------------------------------
; ValidateCode - verifica el formato ABC-123
;   3 letras mayusculas, guion, 3 digitos y fin de cadena (7 caracteres).
; Entrada : ESI = cadena
; Salida  : CF = 0 valido ; CF = 1 invalido
; Modifica: flags. Conserva todos los registros.
;---------------------------------------------------------------------
ValidateCode PROC
    push eax
    push ecx
    push esi
    mov ecx, 3
VCD_letters:
    mov al, [esi]
    cmp al, 'A'
    jb VCD_bad
    cmp al, 'Z'
    ja VCD_bad
    inc esi
    dec ecx
    jnz VCD_letters
    cmp BYTE PTR [esi], '-'
    jne VCD_bad
    inc esi
    mov ecx, 3
VCD_digits:
    mov al, [esi]
    cmp al, '0'
    jb VCD_bad
    cmp al, '9'
    ja VCD_bad
    inc esi
    dec ecx
    jnz VCD_digits
    cmp BYTE PTR [esi], 0       ; no debe haber mas caracteres
    jne VCD_bad
    clc
    jmp VCD_out
VCD_bad:
    stc
VCD_out:
    pop esi
    pop ecx
    pop eax
    ret
ValidateCode ENDP

;---------------------------------------------------------------------
; ValidateName - nombre de 1 a 25 caracteres
;   Rechaza caracteres de control, DEL (7Fh), el separador '|' del
;   archivo y los nombres formados solo por espacios.
; Entrada : ESI = cadena
; Salida  : CF = 0 valido ; CF = 1 invalido
; Modifica: flags. Conserva todos los registros.
;---------------------------------------------------------------------
ValidateName PROC
    push eax
    push ebx
    push ecx
    push esi
    xor ecx, ecx                ; ECX = longitud
    xor ebx, ebx                ; EBX = caracteres distintos de espacio
VNM_loop:
    mov al, [esi]
    test al, al
    jz VNM_end
    cmp al, 20h
    jb VNM_bad                  ; control
    cmp al, 7Fh
    je VNM_bad
    cmp al, '|'
    je VNM_bad
    cmp al, ' '
    je VNM_space
    inc ebx
VNM_space:
    inc ecx
    cmp ecx, MAX_NAME
    ja VNM_bad                  ; mas de 25 caracteres
    inc esi
    jmp VNM_loop
VNM_end:
    test ebx, ebx               ; vacio o solo espacios
    jz VNM_bad
    clc
    jmp VNM_out
VNM_bad:
    stc
VNM_out:
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret
ValidateName ENDP

;---------------------------------------------------------------------
; AskQuantity - pide una cantidad entera mayor que cero
; Entrada : EDX = texto de la pregunta
; Salida  : CF = 0 -> EAX = cantidad ; CF = 1 -> invalida (mensaje ya mostrado)
; Modifica: EAX, flags. Conserva EBX, ECX, EDX, ESI, EDI.
;---------------------------------------------------------------------
AskQuantity PROC
    push edx
    push esi
    call WriteString
    call ReadLine
    mov esi, OFFSET inBuf
    call ParseUInt
    jc AQT_bad
    test eax, eax
    jz AQT_bad
    clc
    jmp AQT_end
AQT_bad:
    mov edx, OFFSET msgBadQty
    call WriteString
    xor eax, eax
    stc
AQT_end:
    pop esi
    pop edx
    ret
AskQuantity ENDP

;---------------------------------------------------------------------
; AskYesNo - pregunta con respuesta S/N
; Entrada : EDX = texto de la pregunta
; Salida  : EAX = 1 si respondio S o s ; EAX = 0 en cualquier otro caso
; Modifica: EAX, flags. Conserva EBX, ECX, EDX, ESI, EDI.
;---------------------------------------------------------------------
AskYesNo PROC
    push edx
    call WriteString
    call ReadLine
    cmp eax, 1
    jne AYN_no
    movzx eax, BYTE PTR inBuf
    cmp al, 'S'
    je AYN_yes
    cmp al, 's'
    je AYN_yes
AYN_no:
    xor eax, eax
    jmp AYN_end
AYN_yes:
    mov eax, 1
AYN_end:
    pop edx
    ret
AskYesNo ENDP

;=====================================================================
;  CATALOGO: BUSQUEDA POR CODIGO
;=====================================================================

;---------------------------------------------------------------------
; FindCode - busca un codigo en una tabla de registros
;   Recorre la tabla con ESI sumando REC_SIZE en cada vuelta y compara
;   los 8 bytes del codigo como dos DWORD.
; Entrada : EDX = codigo ya validado (7 caracteres + 00h)
;           ESI = inicio de la tabla, ECX = numero de registros a revisar
; Salida  : EAX = direccion del registro encontrado, o 0 si no existe
; Modifica: EAX, flags. Conserva EBX, ECX, EDX, ESI, EDI.
;---------------------------------------------------------------------
FindCode PROC
    push ecx
    push esi
    test ecx, ecx
    jz FCD_no
FCD_loop:
    mov eax, [esi+OFF_CODE]
    cmp eax, [edx]
    jne FCD_next
    mov eax, [esi+OFF_CODE+4]
    cmp eax, [edx+4]
    je FCD_found
FCD_next:
    add esi, REC_SIZE           ; siguiente producto
    dec ecx
    jnz FCD_loop
FCD_no:
    xor eax, eax
    jmp FCD_end
FCD_found:
    mov eax, esi
FCD_end:
    pop esi
    pop ecx
    ret
FindCode ENDP

;---------------------------------------------------------------------
; FindInCatalog - busca un codigo en el catalogo en uso
; Entrada : EDX = codigo validado
; Salida  : EAX = direccion del registro, o 0 si no existe
; Modifica: EAX, flags. Conserva EBX, ECX, EDX, ESI, EDI.
;---------------------------------------------------------------------
FindInCatalog PROC
    push ecx
    push esi
    mov esi, OFFSET catalog
    mov ecx, prodCount
    call FindCode
    pop esi
    pop ecx
    ret
FindInCatalog ENDP

;---------------------------------------------------------------------
; AskProduct - pide un codigo, lo valida y localiza el producto
; Entrada : ninguna
; Salida  : EAX = direccion del registro (0 si hubo error; el mensaje
;           ya fue mostrado)
; Modifica: EAX, flags. Conserva EBX, ECX, EDX, ESI, EDI.
;---------------------------------------------------------------------
AskProduct PROC
    push edx
    push esi
    mov edx, OFFSET msgAskCode
    call WriteString
    call ReadLine
    mov esi, OFFSET inBuf
    call ValidateCode
    jc ASP_badCode
    mov edx, OFFSET inBuf
    call FindInCatalog
    test eax, eax
    jnz ASP_end
    mov edx, OFFSET msgNotFound
    call WriteString
    jmp ASP_end                 ; EAX ya vale 0
ASP_badCode:
    mov edx, OFFSET msgBadCode
    call WriteString
    xor eax, eax
ASP_end:
    pop esi
    pop edx
    ret
AskProduct ENDP

;=====================================================================
;  REGLA DEL NEGOCIO Y CALCULOS DE VENTA
;=====================================================================

;---------------------------------------------------------------------
; ComputeSale - importe base, descuento por cantidad y total
;   base      = precio * cantidad
;   descuento = piso(base * 10 / 100) si cantidad >= 10, si no 0
;               (la fraccion de centavo se descarta con DIV entero)
;   total     = base - descuento
; Entrada : EAX = precio unitario (centavos), ECX = cantidad
; Salida  : saleBase, saleDisc, saleFinal (memoria)
;           CF = 1 si hubo desbordamiento (no debe usarse el resultado)
; Modifica: saleBase, saleDisc, saleFinal, flags.
;           Conserva EAX, EBX, ECX, EDX, ESI, EDI.
;---------------------------------------------------------------------
ComputeSale PROC
    push eax
    push ebx
    push edx
    mul ecx                     ; EDX:EAX = precio * cantidad
    jc CSL_ovf                  ; CF=1 si el producto no cabe en 32 bits
    mov saleBase, eax
    mov DWORD PTR saleDisc, 0
    cmp ecx, DISC_MIN_QTY
    jb CSL_final                ; menos de 10 unidades: sin descuento
    mov ebx, DISC_PERCENT
    mul ebx                     ; EDX:EAX = base * 10
    jc CSL_ovf
    xor edx, edx
    mov ebx, 100
    div ebx                     ; EAX = piso(base * 10 / 100)
    mov saleDisc, eax
CSL_final:
    mov eax, saleBase
    sub eax, saleDisc
    mov saleFinal, eax
    clc
    jmp CSL_out
CSL_ovf:
    stc
CSL_out:
    pop edx
    pop ebx
    pop eax
    ret
ComputeSale ENDP

;---------------------------------------------------------------------
; ShowSaleBreakdown - muestra base, descuento (si aplica) y total
; Entrada : saleBase, saleDisc, saleFinal calculados con ComputeSale
; Modifica: flags. Conserva todos los registros.
;---------------------------------------------------------------------
ShowSaleBreakdown PROC
    push eax
    push edx
    mov edx, OFFSET lblBase
    mov eax, saleBase
    call PrintLabelMoney
    cmp DWORD PTR saleDisc, 0
    je SSB_none
    mov edx, OFFSET lblDisc
    mov eax, saleDisc
    call PrintLabelMoney
    jmp SSB_total
SSB_none:
    mov edx, OFFSET msgNoDisc
    call WriteString
SSB_total:
    mov edx, OFFSET lblTotal
    mov eax, saleFinal
    call PrintLabelMoney
    pop edx
    pop eax
    ret
ShowSaleBreakdown ENDP

;=====================================================================
;  OPCIONES DEL MENU
;=====================================================================

;---------------------------------------------------------------------
; RegisterProduct - alta de un producto (opcion 1)
;   Los datos se arman en newRec; el catalogo solo se toca al final,
;   cuando todos los campos ya fueron validados.
; Modifica: catalogo, prodCount, dirty. Conserva todos los registros.
;---------------------------------------------------------------------
RegisterProduct PROC
    pushad
    cmp DWORD PTR prodCount, MAX_PRODUCTS
    jb REG_room
    mov edx, OFFSET msgFull
    call WriteString
    jmp REG_end
REG_room:
    ; ---- codigo ----
    mov edx, OFFSET msgAskCode
    call WriteString
    call ReadLine
    mov esi, OFFSET inBuf
    call ValidateCode
    jc REG_badCode
    mov edx, OFFSET inBuf
    call FindInCatalog
    test eax, eax
    jnz REG_dup
    mov edi, OFFSET newRec + OFF_CODE
    call StrCopy                ; ESI sigue apuntando a inBuf
    ; ---- nombre ----
    mov edx, OFFSET msgAskName
    call WriteString
    call ReadLine
    mov esi, OFFSET inBuf
    call ValidateName
    jc REG_badName
    mov edi, OFFSET newRec + OFF_NAME
    call StrCopy
    ; ---- precio ----
    mov edx, OFFSET msgAskPrice
    call WriteString
    call ReadLine
    mov esi, OFFSET inBuf
    call ParsePrice
    jc REG_badPrice
    mov DWORD PTR newRec[OFF_PRICE], eax
    ; ---- existencia ----
    mov edx, OFFSET msgAskStock
    call WriteString
    call ReadLine
    mov esi, OFFSET inBuf
    call ParseUInt
    jc REG_badStock
    cmp eax, MAX_STOCK
    ja REG_badStock
    mov DWORD PTR newRec[OFF_STOCK], eax
    ; ---- todo es valido: copiar newRec al siguiente espacio libre ----
    mov eax, prodCount
    imul eax, REC_SIZE
    add eax, OFFSET catalog
    mov edi, eax
    mov esi, OFFSET newRec
    mov ecx, REC_SIZE / 4
    cld
    rep movsd
    inc DWORD PTR prodCount
    mov BYTE PTR dirty, 1
    mov edx, OFFSET msgRegOk
    call WriteString
    jmp REG_end
REG_badCode:
    mov edx, OFFSET msgBadCode
    call WriteString
    jmp REG_end
REG_dup:
    mov edx, OFFSET msgDup
    call WriteString
    jmp REG_end
REG_badName:
    mov edx, OFFSET msgBadName
    call WriteString
    jmp REG_end
REG_badPrice:
    mov edx, OFFSET msgBadPrice
    call WriteString
    jmp REG_end
REG_badStock:
    mov edx, OFFSET msgBadStock
    call WriteString
REG_end:
    popad
    ret
RegisterProduct ENDP

;---------------------------------------------------------------------
; ShowInventory - tabla con todos los productos (opcion 2)
;   ESI recorre el catalogo; EBX cuenta los productos restantes.
; Conserva todos los registros.
;---------------------------------------------------------------------
ShowInventory PROC
    pushad
    cmp DWORD PTR prodCount, 0
    jne INV_list
    mov edx, OFFSET msgEmpty
    call WriteString
    jmp INV_end
INV_list:
    mov edx, OFFSET msgInvHeader
    call WriteString
    mov esi, OFFSET catalog
    mov ebx, prodCount
INV_row:
    lea edx, [esi+OFF_CODE]
    mov ecx, 10
    call WriteStrPad
    lea edx, [esi+OFF_NAME]
    mov ecx, 28
    call WriteStrPad
    mov eax, [esi+OFF_PRICE]
    mov edi, OFFSET moneyBuf
    call FormatMoney
    mov edx, OFFSET moneyBuf
    mov ecx, 18
    call WriteStrPad
    mov eax, [esi+OFF_STOCK]
    call PrintUInt
    call Crlf
    add esi, REC_SIZE
    dec ebx
    jnz INV_row
INV_end:
    popad
    ret
ShowInventory ENDP

;---------------------------------------------------------------------
; SearchProduct - busca por codigo y muestra el producto (opcion 3)
; Conserva todos los registros.
;---------------------------------------------------------------------
SearchProduct PROC
    pushad
    call AskProduct
    test eax, eax
    jz SRC_end
    mov esi, eax                ; ESI apunta al registro encontrado
    mov edx, OFFSET msgFound
    call WriteString
    mov edx, OFFSET lblCode
    call WriteString
    lea edx, [esi+OFF_CODE]
    call WriteString
    call Crlf
    mov edx, OFFSET lblName
    call WriteString
    lea edx, [esi+OFF_NAME]
    call WriteString
    call Crlf
    mov edx, OFFSET lblPrice
    mov eax, [esi+OFF_PRICE]
    call PrintLabelMoney
    mov edx, OFFSET lblStock
    mov eax, [esi+OFF_STOCK]
    call PrintLabelUInt
    mov eax, [esi+OFF_PRICE]
    mul DWORD PTR [esi+OFF_STOCK]   ; precio * existencia (<= 99,999,900)
    mov edx, OFFSET lblValue
    call PrintLabelMoney
SRC_end:
    popad
    ret
SearchProduct ENDP

;---------------------------------------------------------------------
; ReceiveStock - suma unidades a un producto existente (opcion 4)
;   La existencia solo cambia si existencia + entrada <= 100.
; Conserva todos los registros.
;---------------------------------------------------------------------
ReceiveStock PROC
    pushad
    call AskProduct
    test eax, eax
    jz RCV_end
    mov ebx, eax                ; EBX = registro (se conserva entre llamadas)
    mov edx, OFFSET msgAskQtyIn
    call AskQuantity
    jc RCV_end
    mov esi, ebx                ; ESI apunta al producto
    mov ecx, eax                ; ECX = unidades recibidas
    mov eax, [esi+OFF_STOCK]
    add eax, ecx
    jc RCV_over                 ; desbordamiento de 32 bits
    cmp eax, MAX_STOCK
    ja RCV_over                 ; supera 100 unidades
    mov [esi+OFF_STOCK], eax    ; ya validado: se actualiza
    mov BYTE PTR dirty, 1
    mov edx, OFFSET msgRecvOk
    call WriteString
    call PrintUInt
    call Crlf
    jmp RCV_end
RCV_over:
    mov edx, OFFSET msgOverStock
    call WriteString
RCV_end:
    popad
    ret
ReceiveStock ENDP

;---------------------------------------------------------------------
; SellProduct - venta de un solo producto (opcion 5)
;   Orden: 1) validar entradas 2) comprobar existencias 3) calcular
;   importe/descuento y nuevos acumulados con deteccion de carry
;   4) SOLO SI TODO FUE VALIDO, actualizar existencias e ingresos.
;   Asi una venta rechazada no deja cambios parciales.
; Conserva todos los registros.
;---------------------------------------------------------------------
SellProduct PROC
    pushad
    call AskProduct
    test eax, eax
    jz SEL_end
    mov ebx, eax                ; EBX = registro del producto
    mov edx, OFFSET msgAskQtySell
    call AskQuantity
    jc SEL_end
    mov ecx, eax                ; ECX = cantidad pedida
    mov esi, ebx                ; ESI apunta al producto
    cmp ecx, [esi+OFF_STOCK]
    ja SEL_noStock              ; pide mas de lo que hay
    mov eax, [esi+OFF_PRICE]
    call ComputeSale            ; base, descuento y total
    jc SEL_ovf
    mov eax, saleFinal
    add eax, sessionIncome      ; nuevo ingreso acumulado
    jc SEL_ovf
    mov edx, saleDisc
    add edx, sessionDisc        ; nuevos descuentos acumulados
    jc SEL_ovf
    ; ---- punto de confirmacion: ya no puede fallar nada ----
    mov sessionIncome, eax
    mov sessionDisc, edx
    sub [esi+OFF_STOCK], ecx    ; descuenta las unidades vendidas
    mov BYTE PTR dirty, 1
    mov edx, OFFSET msgSaleOk
    call WriteString
    mov edx, OFFSET lblProduct
    call WriteString
    lea edx, [esi+OFF_NAME]
    call WriteString
    call Crlf
    mov edx, OFFSET lblQty
    mov eax, ecx
    call PrintLabelUInt
    call ShowSaleBreakdown
    mov edx, OFFSET lblRemain
    mov eax, [esi+OFF_STOCK]
    call PrintLabelUInt
    jmp SEL_end
SEL_noStock:
    mov edx, OFFSET msgNoStock
    call WriteString
    jmp SEL_end
SEL_ovf:
    mov edx, OFFSET msgOvf
    call WriteString
SEL_end:
    popad
    ret
SellProduct ENDP

;---------------------------------------------------------------------
; QuoteSale - cotiza una venta para demostrar la regla (opcion 7)
;   Usa ComputeSale pero no modifica existencias ni ingresos.
; Conserva todos los registros.
;---------------------------------------------------------------------
QuoteSale PROC
    pushad
    call AskProduct
    test eax, eax
    jz QTE_end
    mov ebx, eax
    mov edx, OFFSET msgAskQtyQuote
    call AskQuantity
    jc QTE_end
    mov ecx, eax
    mov esi, ebx
    mov eax, [esi+OFF_PRICE]
    call ComputeSale
    jc QTE_ovf
    mov edx, OFFSET msgQuote
    call WriteString
    mov edx, OFFSET lblProduct
    call WriteString
    lea edx, [esi+OFF_NAME]
    call WriteString
    call Crlf
    mov edx, OFFSET lblQty
    mov eax, ecx
    call PrintLabelUInt
    call ShowSaleBreakdown
    jmp QTE_end
QTE_ovf:
    mov edx, OFFSET msgOvf
    call WriteString
QTE_end:
    popad
    ret
QuoteSale ENDP

;---------------------------------------------------------------------
; ShowSummary - unidades, valor del inventario e ingresos (opcion 6)
;   Valor = suma de precio * existencia con deteccion de desbordamiento.
; Conserva todos los registros.
;---------------------------------------------------------------------
ShowSummary PROC
    pushad
    xor edi, edi                ; EDI = unidades disponibles
    xor ebx, ebx                ; EBX = valor del inventario (centavos)
    mov esi, OFFSET catalog
    mov ecx, prodCount
    test ecx, ecx
    jz SUM_print
SUM_loop:
    mov eax, [esi+OFF_STOCK]
    add edi, eax
    mul DWORD PTR [esi+OFF_PRICE]   ; EDX:EAX = existencia * precio
    jc SUM_ovf
    add ebx, eax
    jc SUM_ovf
    add esi, REC_SIZE
    dec ecx
    jnz SUM_loop
SUM_print:
    mov edx, OFFSET msgSumTitle
    call WriteString
    mov edx, OFFSET lblSumProds
    mov eax, prodCount
    call PrintLabelUInt
    mov edx, OFFSET lblSumUnits
    mov eax, edi
    call PrintLabelUInt
    mov edx, OFFSET lblSumValue
    mov eax, ebx
    call PrintLabelMoney
    mov edx, OFFSET lblSumIncome
    mov eax, sessionIncome
    call PrintLabelMoney
    mov edx, OFFSET lblSumDisc
    mov eax, sessionDisc
    call PrintLabelMoney
    mov edx, OFFSET msgRule
    call WriteString
    jmp SUM_end
SUM_ovf:
    mov edx, OFFSET msgOvf
    call WriteString
SUM_end:
    popad
    ret
ShowSummary ENDP

;=====================================================================
;  ARCHIVO DE INVENTARIO
;  Formato de texto (lineas terminadas en CRLF):
;     INVENTARIO-MASM-V1
;     <numero de productos 0..10>
;     CODIGO|NOMBRE|CENTAVOS|EXISTENCIA      (una linea por producto)
;=====================================================================

;---------------------------------------------------------------------
; AppendUInt - agrega un entero en decimal a un buffer
; Entrada : EAX = valor, EDI = posicion de escritura
; Salida  : EDI avanza tras el ultimo digito
; Modifica: EDI, flags. Conserva EAX y los demas.
;---------------------------------------------------------------------
AppendUInt PROC
    push eax
    call UIntToStr              ; EAX = numero de digitos
    add edi, eax
    pop eax
    ret
AppendUInt ENDP

;---------------------------------------------------------------------
; AskFileName - pide el nombre del archivo (Enter = inventario.txt)
; Salida  : curFile con el nombre elegido
; Conserva todos los registros.
;---------------------------------------------------------------------
AskFileName PROC
    pushad
    mov edx, OFFSET msgAskFile
    call WriteString
    call ReadLine
    test eax, eax
    jz AFN_default
    mov esi, OFFSET inBuf
    jmp AFN_copy
AFN_default:
    mov esi, OFFSET defaultFile
AFN_copy:
    mov edi, OFFSET curFile
    call StrCopy
    popad
    ret
AskFileName ENDP

;---------------------------------------------------------------------
; SaveCatalog - guarda el catalogo en curFile
;   1) arma TODO el contenido en fileBuf  2) crea el archivo
;   3) WriteToFile y verifica que EAX (bytes escritos) = bytes pedidos
;   4) CloseFile. Si algo falla, los datos siguen en memoria.
; Salida  : CF = 0 guardado ; CF = 1 error (mensaje mostrado)
; Conserva todos los registros.
;---------------------------------------------------------------------
SaveCatalog PROC
    pushad
    mov edi, OFFSET fileBuf
    mov edx, OFFSET fileMagic
    call AppendStr
    mov edx, OFFSET strCRLF
    call AppendStr
    mov eax, prodCount
    call AppendUInt
    mov edx, OFFSET strCRLF
    call AppendStr
    mov esi, OFFSET catalog
    mov ebx, prodCount
    test ebx, ebx
    jz SAV_write
SAV_loop:
    lea edx, [esi+OFF_CODE]
    call AppendStr
    mov BYTE PTR [edi], '|'
    inc edi
    lea edx, [esi+OFF_NAME]
    call AppendStr
    mov BYTE PTR [edi], '|'
    inc edi
    mov eax, [esi+OFF_PRICE]
    call AppendUInt
    mov BYTE PTR [edi], '|'
    inc edi
    mov eax, [esi+OFF_STOCK]
    call AppendUInt
    mov edx, OFFSET strCRLF
    call AppendStr
    add esi, REC_SIZE
    dec ebx
    jnz SAV_loop
SAV_write:
    sub edi, OFFSET fileBuf     ; EDI = longitud del contenido
    mov saveLen, edi
    mov edx, OFFSET curFile
    call CreateOutputFile       ; EAX = handle o INVALID_HANDLE_VALUE
    cmp eax, INVALID_HANDLE_VALUE
    jne SAV_open
    mov edx, OFFSET msgSaveErrOpen
    jmp SAV_fail
SAV_open:
    mov hFile, eax
    mov eax, hFile              ; EAX = handle
    mov edx, OFFSET fileBuf     ; EDX = buffer
    mov ecx, saveLen            ; ECX = bytes a escribir
    call WriteToFile            ; EAX = bytes escritos
    mov fileBytes, eax          ; (ECX puede perderse, saveLen no)
    mov eax, hFile
    call CloseFile
    mov eax, fileBytes
    cmp eax, saveLen
    jne SAV_wrErr               ; se escribieron menos bytes de los pedidos
    mov BYTE PTR dirty, 0
    mov edx, OFFSET msgSaveOk
    call WriteString
    call PrintUInt
    call Crlf
    popad
    clc
    ret
SAV_wrErr:
    mov edx, OFFSET msgSaveErrWr
SAV_fail:
    call WriteString
    popad
    stc
    ret
SaveCatalog ENDP

;---------------------------------------------------------------------
; GetField - copia un campo del texto a fieldBuf
; Entrada : ESI = posicion en el texto, DL = caracter terminador
; Salida  : fieldBuf = campo + 00h ; ESI apunta al caracter que detuvo
;           la lectura ; AL = ese caracter (DL o 00h)
;           CF = 1 si el campo esta vacio o es mas largo que FIELD_MAX
; Modifica: ESI, AL, flags. Conserva EBX, ECX, EDX, EDI.
;---------------------------------------------------------------------
GetField PROC
    push ecx
    push edi
    mov edi, OFFSET fieldBuf
    xor ecx, ecx                ; ECX = longitud del campo
GFD_loop:
    mov al, [esi]
    cmp al, dl
    je GFD_stop
    test al, al
    jz GFD_stop                 ; fin del texto
    cmp ecx, FIELD_MAX
    jae GFD_err
    mov [edi], al
    inc edi
    inc esi
    inc ecx
    jmp GFD_loop
GFD_stop:
    mov BYTE PTR [edi], 0
    test ecx, ecx
    jz GFD_err                  ; campo vacio
    clc
    jmp GFD_out
GFD_err:
    mov BYTE PTR [edi], 0
    stc
GFD_out:
    pop edi
    pop ecx
    ret
GetField ENDP

;---------------------------------------------------------------------
; LoadCatalog - lee curFile, valida TODO y solo entonces reemplaza
;   Los registros leidos se arman en tmpCatalog. El catalogo en uso
;   se reemplaza unicamente si encabezado, cantidad, formato de cada
;   campo, rangos y codigos repetidos son correctos.
; Salida  : CF = 0 catalogo reemplazado ; CF = 1 error (catalogo intacto)
; Conserva todos los registros.
;---------------------------------------------------------------------
LoadCatalog PROC
    pushad
    mov edx, OFFSET curFile
    call OpenInputFile          ; EAX = handle o INVALID_HANDLE_VALUE
    cmp eax, INVALID_HANDLE_VALUE
    jne LOD_opened
    mov edx, OFFSET msgLoadNoFile
    jmp LOD_fail
LOD_opened:
    mov hFile, eax
    mov edx, OFFSET fileBuf
    mov ecx, FILE_CAP           ; capacidad de lectura (fileBuf tiene FILE_CAP+1)
    call ReadFromFile           ; EAX = bytes LEIDOS (no la capacidad)
    jc LOD_readErr
    mov fileBytes, eax
    mov eax, hFile
    call CloseFile
    cmp DWORD PTR fileBytes, FILE_CAP
    jae LOD_big                 ; el archivo no cabe completo
    mov ebx, fileBytes
    mov BYTE PTR fileBuf[ebx], 0    ; 00h final para poder recorrer como cadena
    mov esi, OFFSET fileBuf
    call RemoveCR
    mov DWORD PTR ldText, OFFSET fileBuf

    ; ---- linea 1: encabezado ----
    mov esi, ldText
    mov dl, 0Ah
    call GetField
    jc LOD_hdr
    cmp al, 0Ah
    jne LOD_fmt                 ; faltan lineas
    inc esi
    mov ldText, esi
    mov esi, OFFSET fieldBuf
    mov edi, OFFSET fileMagic
    call StrEq
    jne LOD_hdr

    ; ---- linea 2: numero de productos ----
    mov esi, ldText
    mov dl, 0Ah
    call GetField
    jc LOD_fmt
    cmp al, 0Ah
    jne LOD_cnt2
    inc esi
LOD_cnt2:
    mov ldText, esi
    mov esi, OFFSET fieldBuf
    call ParseUInt
    jc LOD_cnt
    cmp eax, MAX_PRODUCTS
    ja LOD_cnt
    mov ldCount, eax
    xor ebx, ebx                ; EBX = registros ya procesados

LOD_rec:
    cmp ebx, ldCount
    jae LOD_recsDone
    imul edi, ebx, REC_SIZE
    add edi, OFFSET tmpCatalog  ; EDI = registro temporal destino

    ; ---- campo 1: codigo ----
    mov esi, ldText
    mov dl, '|'
    call GetField
    jc LOD_bad
    cmp al, '|'
    jne LOD_bad
    inc esi
    mov ldText, esi
    mov esi, OFFSET fieldBuf
    call ValidateCode
    jc LOD_bad
    mov edx, OFFSET fieldBuf    ; codigo repetido entre los ya cargados?
    mov esi, OFFSET tmpCatalog
    mov ecx, ebx
    call FindCode
    test eax, eax
    jnz LOD_bad
    mov esi, OFFSET fieldBuf
    push edi
    add edi, OFF_CODE
    call StrCopy
    pop edi

    ; ---- campo 2: nombre ----
    mov esi, ldText
    mov dl, '|'
    call GetField
    jc LOD_bad
    cmp al, '|'
    jne LOD_bad
    inc esi
    mov ldText, esi
    mov esi, OFFSET fieldBuf
    call ValidateName
    jc LOD_bad
    push edi
    add edi, OFF_NAME
    call StrCopy
    pop edi

    ; ---- campo 3: precio en centavos ----
    mov esi, ldText
    mov dl, '|'
    call GetField
    jc LOD_bad
    cmp al, '|'
    jne LOD_bad
    inc esi
    mov ldText, esi
    mov esi, OFFSET fieldBuf
    call ParseUInt
    jc LOD_bad
    test eax, eax
    jz LOD_bad
    cmp eax, MAX_PRICE
    ja LOD_bad
    mov [edi+OFF_PRICE], eax

    ; ---- campo 4: existencia (termina en fin de linea) ----
    mov esi, ldText
    mov dl, 0Ah
    call GetField
    jc LOD_bad
    cmp al, 0Ah
    jne LOD_f4
    inc esi
LOD_f4:
    mov ldText, esi
    mov esi, OFFSET fieldBuf
    call ParseUInt
    jc LOD_bad
    cmp eax, MAX_STOCK
    ja LOD_bad
    mov [edi+OFF_STOCK], eax
    inc ebx
    jmp LOD_rec

LOD_recsDone:
    mov esi, ldText             ; solo se permiten saltos de linea finales
LOD_tail:
    cmp BYTE PTR [esi], 0Ah
    jne LOD_tailEnd
    inc esi
    jmp LOD_tail
LOD_tailEnd:
    cmp BYTE PTR [esi], 0
    jne LOD_fmt                 ; sobran datos
    ; ---- todo es valido: ahora si se reemplaza el catalogo ----
    cld
    mov esi, OFFSET tmpCatalog
    mov edi, OFFSET catalog
    mov ecx, (MAX_PRODUCTS*REC_SIZE) / 4
    rep movsd
    mov eax, ldCount
    mov prodCount, eax
    mov BYTE PTR dirty, 0
    mov edx, OFFSET msgLoadOk
    call WriteString
    mov eax, ldCount
    call PrintUInt
    call Crlf
    popad
    clc
    ret

LOD_readErr:
    mov eax, hFile
    call CloseFile
    mov edx, OFFSET msgLoadReadErr
    jmp LOD_fail
LOD_big:
    mov edx, OFFSET msgLoadBig
    jmp LOD_fail
LOD_hdr:
    mov edx, OFFSET msgLoadHeader
    jmp LOD_fail
LOD_fmt:
    mov edx, OFFSET msgLoadFormat
    jmp LOD_fail
LOD_cnt:
    mov edx, OFFSET msgLoadCount
    jmp LOD_fail
LOD_bad:
    mov edx, OFFSET msgLoadRec
    call WriteString
    lea eax, [ebx+1]            ; numero de registro (base 1)
    call PrintUInt
    mov edx, OFFSET msgLoadRec2
LOD_fail:
    call WriteString
    popad
    stc
    ret
LoadCatalog ENDP

;---------------------------------------------------------------------
; DoSave / DoLoad - opciones 8 y 9 del menu
; Conservan todos los registros.
;---------------------------------------------------------------------
DoSave PROC
    pushad
    call AskFileName
    call SaveCatalog
    popad
    ret
DoSave ENDP

DoLoad PROC
    pushad
    cmp BYTE PTR dirty, 0
    je DLD_ask
    mov edx, OFFSET msgLoadDirty
    call AskYesNo
    test eax, eax
    jz DLD_cancel
DLD_ask:
    mov esi, OFFSET curFile     ; respaldo del nombre actual
    mov edi, OFFSET prevFile
    call StrCopy
    call AskFileName
    call LoadCatalog
    jnc DLD_end
    mov esi, OFFSET prevFile    ; la carga fallo: se conserva el nombre anterior
    mov edi, OFFSET curFile
    call StrCopy
    jmp DLD_end
DLD_cancel:
    mov edx, OFFSET msgCancelled
    call WriteString
DLD_end:
    popad
    ret
DoLoad ENDP

;---------------------------------------------------------------------
; ConfirmExit - avisa si hay cambios sin guardar antes de salir
; Salida  : CF = 0 -> se puede salir ; CF = 1 -> se cancela la salida
; Conserva todos los registros.
;---------------------------------------------------------------------
ConfirmExit PROC
    pushad
    cmp BYTE PTR dirty, 0
    je CEX_leave
    mov edx, OFFSET msgDirtyExit
    call WriteString
    call ReadLine
    cmp eax, 1
    jne CEX_stay
    movzx eax, BYTE PTR inBuf
    cmp al, 'S'
    je CEX_save
    cmp al, 's'
    je CEX_save
    cmp al, 'N'
    je CEX_leave
    cmp al, 'n'
    je CEX_leave
    jmp CEX_stay
CEX_save:
    call SaveCatalog
    jc CEX_stay                 ; si no se pudo guardar, no se sale
CEX_leave:
    popad
    clc
    ret
CEX_stay:
    popad
    stc
    ret
ConfirmExit ENDP

;=====================================================================
;  PRUEBA INTERNA: CONSERVACION DE REGISTROS Y PILA EQUILIBRADA
;=====================================================================

;---------------------------------------------------------------------
; CanaryCheck - compara ESP y los registros con los valores "canario"
; Entrada : debe llamarse justo despues de un CALL probado
; Salida  : incrementa testFail si algo cambio
; Modifica: testFail, flags. Conserva todos los registros.
;---------------------------------------------------------------------
CanaryCheck PROC
    push eax
    lea eax, [esp+8]            ; ESP del llamador (+4 de CALL, +4 de PUSH EAX)
    cmp eax, testEsp
    jne CNK_bad
    cmp ebx, 0AAAA0001h
    jne CNK_bad
    cmp ecx, 0BBBB0002h
    jne CNK_bad
    cmp edx, 0CCCC0003h
    jne CNK_bad
    cmp esi, OFFSET testPrice
    jne CNK_bad
    cmp edi, OFFSET moneyBuf
    jne CNK_bad
    pop eax
    ret
CNK_bad:
    inc DWORD PTR testFail
    pop eax
    ret
CanaryCheck ENDP

;---------------------------------------------------------------------
; SelfTest - llama 7 procedimientos con registros "canario" (opcion T)
; Conserva todos los registros.
;---------------------------------------------------------------------
SelfTest PROC
    pushad
    mov DWORD PTR testFail, 0
    mov testEsp, esp
    mov edx, OFFSET msgSelfTitle
    call WriteString
    mov ebx, 0AAAA0001h
    mov ecx, 0BBBB0002h
    mov edx, 0CCCC0003h
    mov esi, OFFSET testPrice   ; "185.50"
    mov edi, OFFSET moneyBuf

    call ParsePrice             ; 1) debe devolver EAX = 18550
    call CanaryCheck
    cmp eax, 18550
    je STS_p1
    inc DWORD PTR testFail
STS_p1:
    mov eax, 1205
    call FormatMoney            ; 2) escribe "$12.05 MXN" en moneyBuf
    call CanaryCheck
    mov eax, 987654
    call UIntToStr              ; 3)
    call CanaryCheck
    call ParseUInt              ; 4) (testPrice no es entero: devuelve CF=1)
    call CanaryCheck
    call ValidateCode           ; 5)
    call CanaryCheck
    call ValidateName           ; 6)
    call CanaryCheck
    call StrLen                 ; 7)
    call CanaryCheck

    cmp esp, testEsp            ; la pila debe estar igual que al inicio
    je STS_espOk
    inc DWORD PTR testFail
STS_espOk:
    mov edx, OFFSET msgSelfMoney
    call WriteString
    mov eax, 1205
    call PrintMoney
    call Crlf
    cmp DWORD PTR testFail, 0
    jne STS_bad
    mov edx, OFFSET msgSelfOk
    call WriteString
    jmp STS_end
STS_bad:
    mov edx, OFFSET msgSelfBad
    call WriteString
    mov eax, testFail
    call PrintUInt
    call Crlf
STS_end:
    popad
    ret
SelfTest ENDP

;=====================================================================
;  PROGRAMA PRINCIPAL
;=====================================================================
main PROC
    mov edx, OFFSET msgBanner
    call WriteString
    mov esi, OFFSET defaultFile
    mov edi, OFFSET curFile
    call StrCopy                ; archivo de trabajo inicial
    mov edx, OFFSET msgAutoLoad
    call WriteString
    call LoadCatalog            ; recupera el catalogo si el archivo existe

MN_menu:
    mov edx, OFFSET msgMenu
    call WriteString
    call ReadLine
    cmp eax, 1                  ; la opcion debe ser de un solo caracter
    jne MN_bad
    movzx eax, BYTE PTR inBuf
    cmp al, '1'
    je MN_1
    cmp al, '2'
    je MN_2
    cmp al, '3'
    je MN_3
    cmp al, '4'
    je MN_4
    cmp al, '5'
    je MN_5
    cmp al, '6'
    je MN_6
    cmp al, '7'
    je MN_7
    cmp al, '8'
    je MN_8
    cmp al, '9'
    je MN_9
    cmp al, 'T'
    je MN_T
    cmp al, 't'
    je MN_T
    cmp al, '0'
    je MN_0
MN_bad:
    mov edx, OFFSET msgBadOption
    call WriteString
    jmp MN_menu
MN_1:
    call RegisterProduct
    jmp MN_menu
MN_2:
    call ShowInventory
    jmp MN_menu
MN_3:
    call SearchProduct
    jmp MN_menu
MN_4:
    call ReceiveStock
    jmp MN_menu
MN_5:
    call SellProduct
    jmp MN_menu
MN_6:
    call ShowSummary
    jmp MN_menu
MN_7:
    call QuoteSale
    jmp MN_menu
MN_8:
    call DoSave
    jmp MN_menu
MN_9:
    call DoLoad
    jmp MN_menu
MN_T:
    call SelfTest
    jmp MN_menu
MN_0:
    call ConfirmExit
    jc MN_menu                  ; CF = 1: el usuario cancelo la salida
    exit
main ENDP

END main
