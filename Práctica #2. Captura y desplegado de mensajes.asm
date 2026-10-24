; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #2: Captura y Desplegado de Mensaje
; Descripción: Pide el nombre al usuario, lo muestra en pantalla y dice cuántas letras tiene.

INCLUDE Irvine32.inc

.data
    mensajeEntrada  BYTE "Ingresa tu nombre: ", 0
    mensajeLongitud BYTE "Total de caracteres escritos: ", 0

    nombre          BYTE 30 DUP(0)
    longitud        DWORD ?

.code
main PROC

    ; Pedir el nombre
    mov  edx, OFFSET mensajeEntrada
    call WriteString

    ; Leer lo que escribe el usuario
    mov  edx, OFFSET nombre
    mov  ecx, SIZEOF nombre - 1
    call ReadString

    ; Guardar cuántos caracteres escribió
    mov  longitud, eax
    call Crlf

    ; Mostrar el nombre
    mov  edx, OFFSET nombre
    call WriteString
    call Crlf

    ; Mostrar la cantidad de caracteres
    mov  edx, OFFSET mensajeLongitud
    call WriteString
    mov  eax, longitud
    call WriteDec

    exit

main ENDP
END main
