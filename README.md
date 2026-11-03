# 🛒 Olist E-Commerce - SQL Server Analytics & Database Objects

Este repositorio contiene un proyecto integral de análisis de datos y desarrollo de objetos de base de datos en **Microsoft SQL Server (T-SQL)** sobre el dataset público de e-commerce de **Olist Brasil**.

El objetivo principal es resolver requerimientos de negocio reales orientados a finanzas, logística y expansión comercial, mediante consultas analíticas, procedimientos almacenados validados y vistas desnormalizadas.

---

## 🛠️ Tecnologías y Herramientas
* **Motor de Base de Datos:** Microsoft SQL Server
* **Entorno de Desarrollo:** SQL Server Management Studio (SSMS)
* **Lenguaje:** T-SQL (Transact-SQL)

---

## 📂 Estructura del Proyecto

### 1. Consultas Analíticas Exploratorias
Respuesta a preguntas clave de negocio sobre el rendimiento general del e-commerce:
* **Ticket Promedio e Ingresos:** Análisis del volumen facturado y gasto medio por compra.
* **Evolución Temporal (MoM):** Identificación de picos comerciales (Black Friday) y caídas de ventas.
* **Top Categorías:** Evaluación del volumen de ventas por categoría de producto.
* **Métodos de Pago:** Análisis del uso de tarjeta de crédito, boleto y cuotas promedio.
* **Logística Regional:** Identificación de los 5 estados con mayor facturación.

### 2. Procedimientos Almacenados (`Stored Procedures`)
Objetos dinámicos diseñados para auditoría y reportes operacionales:
* `sp_Reporte_Ventas_Por_Estado`: Reporte automático de ventas filtrado por estado geográfico.
* `sp_Reporte_Ventas_Por_Ano`: Evaluación del rendimiento económico anual.
* `sp_Reporte_Rendimiento`: Auditoría de ventas, volumen de productos y ventana temporal de actividad por vendedor.
* `sp_Reporte_Demoras_Por_Fecha`: Análisis de entregas tardías en ventanas de tiempo específicas.
* `sp_Reporte_Ventas_Por_Rango_Monto`: Reporte de compras por rango de dinero, incorporando validaciones personalizadas de error con `THROW`.

### 3. Vistas Analíticas (`Views`)
Capa de abstracción de datos lista para consumo corporativo y dashboards:
* `vw_Rendimiento_Logistico_Estado`: Monitoreo del porcentaje de entregas a tiempo vs. retrasos por estado.
* `vw_Analisis_Metodos_Pago`: Resumen de recaudación, transacciones únicas y cuotas por método de pago.
* `vw_Tiempos_Entrega_Vendedores`: Medición en días del tiempo de despacho del vendedor vs. tiempo total al cliente.
* `vw_Analisis_Clientes_Estado`: Evaluación de concentración de clientes únicos y tasa de recurrencia por estado.

---

## 💡 Conceptos y Claves Técnicas Aplicadas
* **Control de Excepciones:** Uso de `THROW` con validaciones de negocio independientes (`IF`).
* **Precisión Decimal:** Control de tipos con `CAST` y `DECIMAL(p, s)` para evitar la truncación en divisiones enteras.
* **Agregaciones Condicionales:** Implementación de `SUM(CASE WHEN ...)` para métricas relativas.
* **Optimización y Limpieza:** Filtrado de registros operativos válidos (`delivered`) e inclusión de `NULLIF` para evitar divisiones entre cero.

---

## 🧑‍💻 Autor
* **Jefferson Ruiz** - *Estudiante de Computación e Informática / Data Analytics*
