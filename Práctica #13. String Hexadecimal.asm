; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #13: String Hexadecimal
; Descripción: Convierte un número a texto hexadecimal, dígito por dígito, y lo muestra en pantalla.

INCLUDE Irvine32.inc

.data
    numero DWORD 1234ABCDh
    buffer BYTE 9 DUP(0)

.code
main PROC

    ; Preparar el número, los 8 dígitos y la posición final del buffer
    mov  eax, numero
    mov  ecx, 8
    mov  esi, OFFSET buffer
    add  esi, 7

L1:
    ; Tomar los 4 bits de la derecha
    mov  edx, eax
    and  edx, 0Fh

    ; Si es mayor que 9, se ajusta para llegar a las letras A-F
    cmp  edx, 9
    jbe  Digito
    add  edx, 7

Digito:
    ; Pasar el valor a su carácter y guardarlo
    add  edx, '0'
    mov  [esi], dl

    ; Avanzar al dígito anterior y quitar los 4 bits ya usados
    dec  esi
    shr  eax, 4
    loop L1

    ; Cerrar la cadena con el 0 final
    mov  BYTE PTR [buffer + 8], 0

    ; Mostrar el resultado
    mov  edx, OFFSET buffer
    call WriteString
    call Crlf

    exit

main ENDP
END main
