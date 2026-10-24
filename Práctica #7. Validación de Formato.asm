; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #7: Validación de Formato
; Descripción: Revisa que una cadena tenga el formato de 3 letras mayúsculas, un guion y 3 números.

INCLUDE Irvine32.inc

.data
    cadena      BYTE "TEC-123", 0
    MsgValido   BYTE "Formato válido", 0
    msgInvalido BYTE "Formato inválido", 0

.code
main PROC

    ; Empezar desde la primera letra
    mov  esi, OFFSET cadena
    mov  ecx, 0

validarLetras:
    ; Cada carácter debe estar entre A y Z
    mov  al, [esi]

    cmp  al, 'A'
    jb   invalido

    cmp  al, 'Z'
    ja   invalido

    inc  esi
    inc  ecx

    ; Se revisan 3 letras
    cmp  ecx, 3
    jb   validarLetras

    ; Después de las letras debe venir un guion
    mov  al, [esi]
    cmp  al, '-'
    jne  invalido

    inc  esi
    mov  ecx, 0

validarNumeros:
    ; Cada carácter debe estar entre 0 y 9
    mov  al, [esi]

    cmp  al, '0'
    jb   invalido

    cmp  al, '9'
    ja   invalido

    inc  esi
    inc  ecx

    ; Se revisan 3 números
    cmp  ecx, 3
    jb   validarNumeros

    ; Al final no debe haber más caracteres
    cmp         BYTE PTR [esi], 0
    jne  invalido

    ; Si llegó hasta aquí, el formato es correcto
    mov  edx, OFFSET MsgValido
    call WriteString
    call Crlf
    jmp  fin

invalido:
    mov  edx, OFFSET msgInvalido
    call WriteString
    call Crlf

fin:
    exit

main ENDP
END main
