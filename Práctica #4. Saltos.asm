; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #4: Saltos
; Descripción: Compara dos números y, usando saltos, muestra si son iguales o diferentes.

INCLUDE Irvine32.inc

.data
    msgIguales   BYTE "Los dos números son iguales", 0
    msgDiferente BYTE "Los dos números son diferentes", 0

.code
main PROC

    ; Valores que se van a comparar
    mov  eax, 10
    mov  ebx, 10

    ; Si son iguales, salta a la etiqueta iguales
    cmp  eax, ebx
    je   iguales

    ; Si no saltó, los valores son diferentes
    mov  edx, OFFSET msgDiferente
    call WriteString
    jmp  fin

iguales:
    mov  edx, OFFSET msgIguales
    call WriteString

fin:
    call Crlf
    exit

main ENDP
END main
