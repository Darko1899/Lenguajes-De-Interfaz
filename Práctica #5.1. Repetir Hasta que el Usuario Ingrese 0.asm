; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #5.1: Repetir Hasta que el Usuario Ingrese 0
; Descripción: Pide números una y otra vez e indica si son positivos o negativos hasta que se escriba 0.

INCLUDE Irvine32.inc

.data
    msgNumero   BYTE "Escribe un número: ", 0
    msgPositivo BYTE "El número es positivo", 0
    msgNegativo BYTE "El número es negativo", 0
    msgSalir    BYTE "Programa terminado", 0

.code
main PROC

ciclo:
    ; Pedir un número
    mov  edx, OFFSET msgNumero
    call WriteString
    call ReadInt

    ; Compararlo con 0 y decidir a dónde ir
    cmp  eax, 0
    je   fin
    jg   positivo
    jl   negativo

positivo:
    mov  edx, OFFSET msgPositivo
    call WriteString
    call Crlf
    jmp  ciclo

negativo:
    mov  edx, OFFSET msgNegativo
    call WriteString
    call Crlf
    jmp  ciclo

fin:
    mov  edx, OFFSET msgSalir
    call WriteString
    call Crlf
    exit

main ENDP
END main
