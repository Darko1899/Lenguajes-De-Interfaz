; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #9: Push y Pop
; Descripción: Usa PUSH y POP para guardar y recuperar valores en la pila, y CALL y RET para llamar un procedimiento.

INCLUDE Irvine32.inc

.code
main PROC

    ; Bloque 1: guardar un valor y sacarlo en otro registro
    mov  eax, 500
    push eax
    nop

    mov  ebx, 0
    pop  ebx
    nop

    ; Bloque 2: el último en entrar es el primero en salir
    mov  eax, 10
    push eax
    mov  eax, 20
    push eax
    mov  eax, 30
    push eax
    nop

    pop  eax
    pop  ebx
    pop  ecx
    nop

    ; Bloque 3: guardar registros antes de cambiarlos y luego recuperarlos
    mov  eax, 100
    mov  ebx, 200

    push eax
    push ebx

    mov  eax, 999
    mov  ebx, 888

    pop  ebx
    pop  eax
    nop

    ; Bloque 4: llamar a un procedimiento
    mov  eax, 50
    mov  ebx, 666
    call aumentarDiez
    nop

    exit

main ENDP

; Le suma 10 a EAX sin perder el valor que tenía EBX
aumentarDiez PROC
    nop
    push ebx
    nop

    mov  ebx, 10
    add  eax, ebx
    nop

    pop  ebx
    nop
    ret
aumentarDiez ENDP

END main
