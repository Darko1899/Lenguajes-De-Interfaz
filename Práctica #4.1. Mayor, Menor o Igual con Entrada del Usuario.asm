; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #4.1: Mayor, Menor o Igual con Entrada del Usuario
; Descripción: Pide dos números al usuario y, con saltos, indica si el primero es mayor, menor o igual al segundo.

INCLUDE Irvine32.inc

.data
    msgNum1    BYTE "Escribe el primer número: ", 0
    msgNum2    BYTE "Escribe el segundo número: ", 0

    msgMayor   BYTE "El primer número es mayor que el segundo", 0
    msgMenor   BYTE "El primer número es menor que el segundo", 0
    msgIguales BYTE "Los dos números son iguales", 0

    num1       DWORD ?
    num2       DWORD ?

.code
main PROC

    ; Pedir el primer número
    mov  edx, OFFSET msgNum1
    call WriteString
    call ReadInt
    mov  num1, eax

    ; Pedir el segundo número
    mov  edx, OFFSET msgNum2
    call WriteString
    call ReadInt
    mov  num2, eax

    ; Compararlos y saltar según el resultado
    mov  eax, num1
    mov  ebx, num2
    cmp  eax, ebx
    jg   mayor
    jl   menor

    ; Si no fue mayor ni menor, son iguales
    mov  edx, OFFSET msgIguales
    call WriteString
    jmp  fin

mayor:
    mov  edx, OFFSET msgMayor
    call WriteString
    jmp  fin

menor:
    mov  edx, OFFSET msgMenor
    call WriteString

fin:
    call Crlf
    exit

main ENDP
END main
