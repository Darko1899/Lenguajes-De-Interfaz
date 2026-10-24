; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #14: Captura y Almacenamiento de Dato Numérico
; Descripción: Pide la cantidad de productos recibidos, valida que sea de 1 a 99 y la suma al inventario.

INCLUDE Irvine32.inc

.data
    mensaje          BYTE "Escribe la cantidad de ESP32 recibidas (1-99): ", 0
    mensajeError     BYTE "Error: escribe un número entre 1 y 99.", 0
    mensajeFinal     BYTE "Existencia actual: ", 0
    mensajeUnidades  BYTE " unidades", 0

    cadena           BYTE 10 DUP(0)
    cadenaSalida     BYTE 12 DUP(0)

    cantidadRecibida DWORD 0
    existenciaActual DWORD 25

.code
main PROC

Capturar:
    ; Leer la cantidad como texto
    mov  edx, OFFSET mensaje
    call WriteString

    mov  edx, OFFSET cadena
    mov  ecx, SIZEOF cadena - 1
    call ReadString

    ; Debe tener 1 o 2 caracteres
    cmp  eax, 1
    jb   Error
    cmp  eax, 2
    ja   Error

    mov  ecx, eax
    mov  esi, OFFSET cadena
    mov  eax, 0

Convertir:
    ; Cada carácter debe ser un dígito
    movzx ebx, BYTE PTR [esi]
    cmp  bl, '0'
    jb   Error
    cmp  bl, '9'
    ja   Error

    ; Pasarlo a número y acumularlo
    sub  ebx, '0'
    imul eax, eax, 10
    add  eax, ebx

    inc  esi
    loop Convertir

    ; El número debe estar entre 1 y 99
    cmp  eax, 1
    jb   Error
    cmp  eax, 99
    ja   Error

    ; Guardar la cantidad y sumarla al inventario
    mov  cantidadRecibida, eax
    add  eax, existenciaActual
    mov  existenciaActual, eax

    ; Mostrar la existencia nueva
    mov  edx, OFFSET mensajeFinal
    call WriteString

    mov  eax, existenciaActual
    mov  edi, OFFSET cadenaSalida
    call ConvertirDecimal

    mov  edx, OFFSET cadenaSalida
    call WriteString

    mov  edx, OFFSET mensajeUnidades
    call WriteString
    call Crlf
    jmp  Salir

Error:
    ; Avisar del error y volver a pedir
    mov  edx, OFFSET mensajeError
    call WriteString
    call Crlf
    jmp  Capturar

Salir:
    exit

main ENDP

; Convierte el número de EAX en texto y lo deja donde apunta EDI
ConvertirDecimal PROC
    push eax
    push ebx
    push ecx
    push edx
    push edi

    mov  ebx, 10
    mov  ecx, 0

Dividir:
    ; Sacar el último dígito y guardarlo en la pila
    mov  edx, 0
    div  ebx
    add  dl, '0'
    push edx
    inc  ecx

    cmp  eax, 0
    jne  Dividir

Guardar:
    ; Sacar los dígitos de la pila para que queden en orden
    pop  eax
    mov  [edi], al
    inc  edi
    loop Guardar

    mov              BYTE PTR [edi], 0

    pop  edi
    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    ret
ConvertirDecimal ENDP

END main
