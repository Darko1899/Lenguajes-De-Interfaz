; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #8: Operaciones Aritméticas
; Descripción: Hace sumas, restas, multiplicaciones y divisiones para ver cómo cambian los registros y las banderas.

INCLUDE Irvine32.inc

.code
main PROC

    ; 1. Suma y resta
    mov  eax, 50
    mov  ebx, 20
    add  eax, ebx
    sub  eax, 15
    nop

    ; 2. Carry: 255 + 1 no cabe en 8 bits
    mov  eax, 0
    mov  al, 255
    add  al, 1
    nop

    ; 3. Overflow: 127 + 1 se pasa del límite con signo
    mov  eax, 0
    mov  al, 127
    add  al, 1
    nop

    ; 4. Multiplicación que cabe en 32 bits
    mov  eax, 25
    mov  ebx, 3
    mul  ebx
    nop

    ; 5. Multiplicación que ocupa más de 32 bits (usa EDX y EAX)
    mov  eax, 65537
    mov  ebx, 65537
    mul  ebx
    nop

    ; 6. Multiplicación con signo
    mov  eax, -5
    imul eax, eax, 3
    nop

    ; 7. División sin signo
    mov  eax, 125
    mov  edx, 0
    mov  ebx, 12
    div  ebx
    nop

    ; 8. División con signo
    mov  eax, -125
    cdq
    mov  ebx, 12
    idiv ebx
    nop

    exit

main ENDP
END main
