; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #6: Decremento e Incremento
; Descripción: Pide un PIN y da máximo 3 intentos; si se acaban, el acceso se bloquea.

INCLUDE Irvine32.inc

.data
    msgPIN       BYTE "Escribe el PIN: ", 0
    msgIntentos  BYTE "Intentos que te quedan: ", 0
    msgError     BYTE "PIN incorrecto", 0
    msgAcceso    BYTE "ACCESO PERMITIDO", 0
    msgBloqueado BYTE "ACCESO BLOQUEADO", 0

    pinCorrecto = 1234

.code
main PROC

    ; Tres intentos disponibles
    mov  ebx, 3

intentar:
    mov  edx, OFFSET msgPIN
    call WriteString
    call ReadInt

    ; Si el PIN coincide, se da acceso
    cmp  eax, pinCorrecto
    je   acceso

    ; Si no coincide, avisar y quitar un intento
    mov  edx, OFFSET msgError
    call WriteString
    call Crlf

    dec  ebx
    jz   bloqueado

    ; Mostrar cuántos intentos quedan
    mov  edx, OFFSET msgIntentos
    call WriteString
    mov  eax, ebx
    call WriteDec
    call Crlf
    jmp  intentar

acceso:
    mov  edx, OFFSET msgAcceso
    call WriteString
    call Crlf
    jmp  fin

bloqueado:
    mov  edx, OFFSET msgBloqueado
    call WriteString
    call Crlf

fin:
    exit

main ENDP
END main
