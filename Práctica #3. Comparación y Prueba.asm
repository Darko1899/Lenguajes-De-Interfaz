; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #3: Comparación y Prueba
; Descripción: Usa CMP, ADD y TEST para ver cómo cambian las banderas del procesador en cada caso.

INCLUDE Irvine32.inc

.code
main PROC

    ; Caso 1: Bandera Zero (se comparan valores iguales)
    mov  ebx, 1
    cmp  ebx, 1
    call DumpRegs

    mov  eax, 01h
    cmp  eax, ebx
    call DumpRegs

    mov  cl, 11111111b
    cmp  cl, cl
    call DumpRegs

    ; Caso 2: Bandera Sign (negativo contra positivo)
    mov  eax, 0
    mov  ebx, 0
    mov  al, -5
    mov  bl, 1
    cmp  al, bl
    call DumpRegs

    ; Caso 3: Bandera Carry (la suma se pasa del límite de AL)
    mov  eax, 0
    mov  ebx, 0
    mov  al, 255
    add  al, 1
    call DumpRegs

    ; Caso 4: Bandera Overflow (el resultado no cabe con signo)
    mov  eax, 0
    mov  ebx, 0
    mov  al, -128
    mov  bl, 1
    cmp  al, bl
    call DumpRegs

    ; Caso 5: TEST (revisa bits sin cambiar el valor)
    mov  eax, 5            ; 00000101b
    test eax, 1            ; el último bit es 1, por eso el resultado no es cero
    call DumpRegs

    mov  eax, 0
    mov  al, 10000000b
    test al, al
    call DumpRegs

    exit

main ENDP
END main
