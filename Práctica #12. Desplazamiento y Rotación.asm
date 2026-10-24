; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #12: Desplazamiento y Rotación
; Descripción: Mueve los bits de un registro a la izquierda o a la derecha con desplazamientos y rotaciones.

INCLUDE Irvine32.inc

.code
main PROC

    ; Dejar los registros en cero
    mov  eax, 0
    mov  ebx, 0
    mov  ecx, 0
    mov  edx, 0

    ; SHL: mover 1 posición a la izquierda
    mov  al, 10000000b
    shl  al, 1
    call DumpRegs
    call WriteBin
    call Crlf

    ; SHR: mover 1 posición a la derecha
    mov  al, 00001101b
    shr  al, 1
    call DumpRegs
    call WriteBin
    call Crlf

    ; SAR: mover a la derecha sin perder el signo
    mov  al, -8
    sar  al, 1
    call DumpRegs
    call WriteBin
    call Crlf

    ; SAR con un número impar
    mov  al, -9
    sar  al, 1
    call DumpRegs
    call WriteBin
    call Crlf

    ; SHL: mover 2 posiciones a la izquierda
    mov  al, 00001111b
    shl  al, 2
    call DumpRegs
    call WriteBin
    call Crlf

    ; SHR: mover 2 posiciones usando CL
    mov  al, 00001111b
    mov  cl, 2
    shr  al, cl
    call DumpRegs
    call WriteBin
    call Crlf

    ; ROR: rotar a la derecha
    mov  al, 10000001b
    ror  al, 1
    call DumpRegs
    call WriteBin
    call Crlf

    ; ROL: rotar a la izquierda
    mov  al, 10000001b
    rol  al, 1
    call DumpRegs
    call WriteBin
    call Crlf

    ; RCL: rotar a la izquierda pasando por el acarreo
    clc
    mov  al, 10000001b
    rcl  al, 1
    call DumpRegs
    call WriteBin
    call Crlf

    ; RCR: rotar a la derecha pasando por el acarreo
    clc
    mov  al, 10000001b
    rcr  al, 1
    call DumpRegs
    call WriteBin
    call Crlf

    exit

main ENDP
END main
