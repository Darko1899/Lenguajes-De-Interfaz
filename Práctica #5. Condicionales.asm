; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #5: Condicionales
; Descripción: Imprime los números del 1 al 100 usando un ciclo y una condición al final.

INCLUDE Irvine32.inc

.code
main PROC

    ; El contador empieza en 1
    mov  ebx, 1

ciclo:
    ; Mostrar el número actual
    mov  eax, ebx
    call WriteDec
    call Crlf

    ; Sumar 1 al contador
    inc  ebx

    ; Mientras no pase de 100, repetir
    cmp  ebx, 100
    jle  ciclo

    exit

main ENDP
END main
