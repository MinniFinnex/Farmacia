from flask import Flask, render_template, request, redirect
from datetime import datetime, date, timedelta
import pymysql

app = Flask(__name__)

def conectar_db():
    return pymysql.connect(host='localhost', user='root', db='cruz_roja', charset='utf8mb4', cursorclass=pymysql.cursors.DictCursor)

@app.route('/devolver/<int:id>')
def devolver(id):
    conn = conectar_db()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM productos WHERE id = %s", (id,))
    producto = cursor.fetchone()

    if producto:
        hoy = date.today()
        reingreso = hoy + timedelta(days=3)

        # Historial de eliminados
        cursor.execute("""
            INSERT INTO historial_eliminados (nombre, lote, cantidad, fecha_caducidad, motivo, fecha_eliminacion)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            producto['nombre'],
            producto['lote'],
            producto['cantidad'],
            producto['fecha_caducidad'],
            'Devuelto al proveedor',
            hoy
        ))

        # Log de devolución
        cursor.execute("""
            INSERT INTO logs_devoluciones (nombre, lote, cantidad, fecha_caducidad, fecha_devolucion, fecha_reingreso_esperada, motivo)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            producto['nombre'],
            producto['lote'],
            producto['cantidad'],
            producto['fecha_caducidad'],
            hoy,
            reingreso,
            'Devuelto por vencimiento o defecto'
        ))

        # Eliminar original
        cursor.execute("UPDATE productos SET eliminado = 1 WHERE id = %s", (id,))

        conn.commit()  # Confirmamos primero antes del INSERT que dispara el trigger

        # Reinsertar producto con misma info, fecha futura
        cursor.execute("""
            INSERT INTO productos (nombre, lote, cantidad, fecha_caducidad, precio, eliminado)
            VALUES (%s, %s, %s, %s, %s, 0)
        """, (
            producto['nombre'],
            producto['lote'],
            producto['cantidad'],
            producto['fecha_caducidad'],
            producto['precio']
        ))

        conn.commit()

    conn.close()
    return redirect('/medicamentos')


@app.route('/logs_devoluciones')
def logs_devoluciones():
    conn = conectar_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM logs_devoluciones ORDER BY fecha_devolucion DESC")
    logs = cursor.fetchall()
    conn.close()
    return render_template('logs.html', logs=logs)


@app.route('/borrar_historial', methods=['POST'])
def borrar_historial():
    conn = conectar_db()
    cursor = conn.cursor()

    cursor.execute("DELETE FROM historial_eliminados")

    conn.commit()
    conn.close()
    return redirect('/eliminados')


@app.route('/vaciar_reporte', methods=['POST'])
def vaciar_reporte():
    conn = conectar_db()
    cursor = conn.cursor()

    # Elimina de productos vencidos
    cursor.execute("DELETE FROM productos WHERE fecha_caducidad <= %s AND eliminado = 0", (date.today(),))

    conn.commit()
    conn.close()
    return redirect('/reporte')


@app.route('/medicamentos')
def medicamentos():
    generar_alertas()  # Para que actualice alertas/promociones antes de mostrar
    conn = conectar_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM productos WHERE eliminado = 0")
    productos = cursor.fetchall()
    conn.close()
    return render_template('medicamentos.html', productos=productos, now=datetime.now())

def generar_alertas():
    conn = conectar_db()
    cursor = conn.cursor()

    hoy = date.today()

    cursor.execute("SELECT * FROM productos WHERE eliminado = 0")
    productos = cursor.fetchall()

    for p in productos:
        fecha_caducidad = p['fecha_caducidad']
        dias_restantes = (fecha_caducidad - hoy).days
        alerta = None
        promocion = None
        precio_base = p['precio']
        nuevo_precio = None

        # Detección de alertas
        if dias_restantes < 0:
            alerta = 'roja'
        elif dias_restantes <= 7:
            alerta = 'naranja'
        elif dias_restantes <= 30:
            alerta = 'amarilla'

        # Aplicación de promociones
        if 15 <= dias_restantes <= 30:
            promocion = 0.10
        elif 8 <= dias_restantes <= 14:
            promocion = 0.25
        elif 0 <= dias_restantes <= 7:
            promocion = 0.50

        precio_base = float(p['precio'])
    


        # Registrar alerta si no existe aún
        if alerta:
            cursor.execute("SELECT * FROM alertas WHERE producto_id = %s AND tipo_alerta = %s", (p['id'], alerta))
            existe = cursor.fetchone()
            if not existe:
                cursor.execute(
                    "INSERT INTO alertas (producto_id, tipo_alerta, fecha_alerta) VALUES (%s, %s, %s)",
                    (p['id'], alerta, hoy)
                )

        # Aplicar promoción si corresponde
        if promocion is not None:
            nuevo_precio = round(precio_base * (1 - promocion), 2)
            cursor.execute("""
                UPDATE productos
                SET promocion_activa = 1, precio_promocion = %s
                WHERE id = %s
            """, (nuevo_precio, p['id']))
        else:
            # Si ya no califica para promoción, quitarla
            cursor.execute("""
                UPDATE productos
                SET promocion_activa = 0, precio_promocion = NULL
                WHERE id = %s
            """, (p['id'],))

    conn.commit()
    conn.close()

@app.route('/')
def index():
    generar_alertas()
    conn = conectar_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM productos WHERE eliminado = 0")
    productos = cursor.fetchall()
    conn.close()
    return render_template('index.html', productos=productos, now=datetime.now())

@app.route('/registrar', methods=['GET', 'POST'])
def registrar():
    if request.method == 'POST':
        nombre = request.form['nombre']
        lote = request.form['lote']
        cantidad = request.form['cantidad']
        fecha = request.form['fecha_caducidad']
        precio = request.form['precio']

        if not precio:
            mensaje = "El campo precio es obligatorio."
            return render_template('registrar.html', mensaje=mensaje)

        try:
            precio = float(precio)
        except ValueError:
            mensaje = "El precio debe ser un número válido."
            return render_template('registrar.html', mensaje=mensaje)

        conn = conectar_db()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM productos WHERE nombre = %s AND lote = %s AND eliminado = 0", (nombre, lote))
        existente = cursor.fetchone()

        if existente:
            nueva_cantidad = existente['cantidad'] + int(cantidad)
            cursor.execute("""
                UPDATE productos SET cantidad = %s, precio = %s WHERE id = %s
            """, (nueva_cantidad, precio, existente['id']))
        else:
            cursor.execute("""
                INSERT INTO productos (nombre, lote, cantidad, fecha_caducidad, precio, eliminado)
                VALUES (%s, %s, %s, %s, %s, 0)
            """, (nombre, lote, cantidad, fecha, precio))

        conn.commit()
        conn.close()
        return redirect('/registro')
    return render_template('registrar.html')


@app.route('/eliminar/<int:id>')
def eliminar(id):
    conn = conectar_db()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM productos WHERE id = %s", (id,))
    producto = cursor.fetchone()

    if producto:
        cursor.execute("""
            INSERT INTO historial_eliminados (nombre, lote, cantidad, fecha_caducidad, motivo, fecha_eliminacion)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (producto['nombre'], producto['lote'], producto['cantidad'], producto['fecha_caducidad'], 'Eliminado manualmente', date.today()))
        cursor.execute("UPDATE productos SET eliminado = 1 WHERE id = %s", (id,))

    conn.commit()
    conn.close()
    return redirect('/eliminados')

@app.route('/reporte')
def reporte():
    conn = conectar_db()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM productos WHERE fecha_caducidad <= %s AND eliminado = 0", (date.today(),))
    vencidos = cursor.fetchall()

    total = sum(float(p['precio'] or 0) * p['cantidad'] for p in vencidos)
    conn.close()
    return render_template('reporte.html', vencidos=vencidos, total=total)

@app.route('/eliminados')
def eliminados():
    conn = conectar_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM historial_eliminados")
    historial = cursor.fetchall()
    conn.close()
    return render_template('eliminados.html', historial=historial)

if __name__ == '__main__':
    app.run(debug=True)