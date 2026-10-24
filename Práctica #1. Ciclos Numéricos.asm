; Materia: Lenguajes de Interfaz
; Alumno: Jose Ramses Alvarez Hicks
; Horario: 8:00-9:00 AM
; Docente: Dr.José Luis Medina Jiménez
; Práctica #1: Ciclos Numericos 
; Descripción: Un programa que al iniciarse nos muestra de manera repetida el mensaje "Hola Mundo"
INCLUDE Irvine32.inc

.data
mensaje BYTE "Hola, mundo: ", 0 

.code
main PROC
 mov ecx, 5 ; Numero de veces que se repite el ciclo

 ciclo:
  mov edx, OFFSET mensaje  ; Muestra el mensaje
   call writeString
   call crlf 
   loop ciclo ; ciclo para repetir hasta que ECX llegue a 0
   exit
main ENDP 

END main 
