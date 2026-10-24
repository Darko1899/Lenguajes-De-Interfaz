; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #11: Operaciones Lógicas
; Descripción: Usa AND, OR, XOR, NOT y TEST para revisar y cambiar bits que representan estados.

INCLUDE Irvine32.inc

.code
main PROC

    ; Significado de cada bit:
    ;   bit 0 = computadora encendida
    ;   bit 1 = alarma
    ;   bit 2 = conectado
    ; Estado de partida: 00000101

    ; AND: sacar el estado de encendido
    mov  eax, 0
    mov  ebx, 0
    mov  al, 00000101b
    mov  bl, al
    and  bl, 00000111b
    call DumpRegs
    nop

    ; OR: prender la alarma
    mov  al, 00000101b
    or   al, 00000010b
    call DumpRegs
    nop

    ; XOR: cambiar el estado de conectado
    mov  al, 00000101b
    xor  al, 00000100b
    call DumpRegs
    nop

    ; NOT: invertir todos los bits
    mov  al, 00000101b
    not  al
    call DumpRegs
    nop

    ; TEST: ver si la alarma está prendida y saltar según el resultado
    mov  al, 00000101b
    test al, 00000010b
    jz   alarmaApagada

    ; Alarma prendida
    mov  ebx, 1
    jmp  finTest

alarmaApagada:
    mov  ebx, 0

finTest:
    call DumpRegs
    nop

    exit

main ENDP
END main
