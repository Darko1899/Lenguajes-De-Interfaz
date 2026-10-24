; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #10: Cadena con Decimal
; Descripción: Calcula el avance de una descarga (bytes bajados, faltantes y porcentaje) y los muestra como texto.

INCLUDE Irvine32.inc

.data
    ; Datos de la descarga
    tamArchivo  DWORD 100000
    bloques     DWORD 125
    tamBloque   DWORD 512

    ; Resultados
    descargados DWORD ?
    pendientes  DWORD ?
    porcentaje  DWORD ?
    grupos      DWORD ?
    residuo     DWORD ?

    ; Textos
    msg1        BYTE "Bytes descargados: ", 0
    msg2        BYTE "Bytes pendientes: ", 0
    msg3        BYTE "Porcentaje de avance: ", 0
    msg4        BYTE "Grupos completos de 1024: ", 0
    msg5        BYTE "Bytes sobrantes: ", 0
    simbolo     BYTE "%", 0

    ; Aquí se arma el número convertido a texto
    buffer      BYTE 11 DUP(0)

.code
main PROC

    ; Bytes descargados = bloques x tamaño de bloque
    mov  eax, bloques
    mul  tamBloque
    mov  descargados, eax

    ; Bytes que faltan por descargar
    mov  eax, tamArchivo
    sub  eax, descargados
    mov  pendientes, eax

    ; Porcentaje = (descargados x 100) / total
    mov  eax, descargados
    mov  ebx, 100
    mul  ebx
    mov  ebx, tamArchivo
    div  ebx
    mov  porcentaje, eax

    ; Cuántos grupos de 1024 caben y cuánto sobra
    mov  eax, descargados
    mov  edx, 0
    mov  ebx, 1024
    div  ebx
    mov  grupos, eax
    mov  residuo, edx

    ; Mostrar bytes descargados
    mov  edx, OFFSET msg1
    call WriteString
    mov  eax, descargados
    mov  esi, OFFSET buffer
    call convertirDecimal
    mov  edx, OFFSET buffer
    call WriteString
    call Crlf

    ; Mostrar bytes pendientes
    mov  edx, OFFSET msg2
    call WriteString
    mov  eax, pendientes
    mov  esi, OFFSET buffer
    call convertirDecimal
    mov  edx, OFFSET buffer
    call WriteString
    call Crlf

    ; Mostrar porcentaje
    mov  edx, OFFSET msg3
    call WriteString
    mov  eax, porcentaje
    mov  esi, OFFSET buffer
    call convertirDecimal
    mov  edx, OFFSET buffer
    call WriteString
    mov  edx, OFFSET simbolo
    call WriteString
    call Crlf

    ; Mostrar grupos completos
    mov  edx, OFFSET msg4
    call WriteString
    mov  eax, grupos
    mov  esi, OFFSET buffer
    call convertirDecimal
    mov  edx, OFFSET buffer
    call WriteString
    call Crlf

    ; Mostrar lo que sobra
    mov  edx, OFFSET msg5
    call WriteString
    mov  eax, residuo
    mov  esi, OFFSET buffer
    call convertirDecimal
    mov  edx, OFFSET buffer
    call WriteString
    call Crlf

    exit

main ENDP

; Convierte el número de EAX en texto y lo deja en el buffer al que apunta ESI
convertirDecimal PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; Se empieza a escribir desde el final del buffer
    mov  edi, esi
    add  edi, 10
    mov         BYTE PTR [edi], 0

    mov  ebx, 10

    ; Si el número es 0, solo se escribe el carácter '0'
    cmp  eax, 0
    jne  convertir
    dec  edi
    mov         BYTE PTR [edi], '0'
    jmp  copiar

convertir:
    ; Dividir entre 10; el residuo es el último dígito
    mov  edx, 0
    div  ebx
    add  dl, '0'
    dec  edi
    mov  [edi], dl

    cmp  eax, 0
    jne  convertir

copiar:
    ; Pasar el texto al inicio del buffer
    mov  al, [edi]
    mov  [esi], al
    inc  edi
    inc  esi
    cmp  al, 0
    jne  copiar

    pop  edi
    pop  esi
    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    ret
convertirDecimal ENDP

END main
