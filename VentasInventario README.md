# Instrucciones de Compilación y Ejecución (MASM x86)



## 1. Configuración del Proyecto
1. Abre Visual Studio y crea un **Proyecto Vacío (C++)**.
2. Haz clic derecho en el proyecto -> **Dependencias de compilación** -> **Personalizaciones de compilación...** y marca la opción **masm**.
3. Agrega un nuevo elemento al proyecto (Archivo C++), nómbralo `VentasInventario.asm` y pega el código fuente.
4. Copia los archivos `inventario.txt` e `inventario_invalido.txt` en la misma carpeta donde se encuentra tu proyecto (exactamente al mismo nivel que el archivo `.vcxproj`).

## 2. Enlace con Irvine32
Haz clic derecho en el proyecto -> **Propiedades** y configura lo siguiente:
* **Vinculador -> General -> Directorios de bibliotecas adicionales:** Agrega `C:\Irvine`
* **Vinculador -> Entrada -> Dependencias adicionales:** Escribe `irvine32.lib;` al inicio de la línea.
* **Microsoft Macro Assembler -> General -> Rutas de acceso de inclusión:** Agrega `C:\Irvine`

Aplica los cambios y cierra la ventana de propiedades.

## 3. Compilación y Ejecución
Presiona **Ctrl + F5** para compilar y ejecutar el programa en la consola.

## 4. Comprobación de Errores (Archivo Inválido)
El archivo `inventario_invalido.txt` sirve para demostrar al profesor que el programa detecta errores de formato y no corrompe la memoria. Para probarlo:
1. Con el programa en ejecución, elige la **opción 9** del menú (Cargar inventario desde archivo).
2. Cuando te pregunte el nombre del archivo, escribe `inventario_invalido.txt` y presiona Enter.
3. El programa mostrará un mensaje de error (ya que el archivo tiene formato dañado y datos repetidos) y mantendrá el inventario actual intacto, comprobando que las validaciones son seguras.