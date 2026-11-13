
/*
olist_order_items_dataset ---> Detalle de productos comprados en cada orden 
olist_orders_dataset ---> Cabecera de órdenes
olist_customers_dataset ---> Clientes
olist_products_dataset ---> Catálogo de productos
olist_sellers_dataset ---> Vendedores
olist_order_payments_dataset ---> Métodos de pago
olist_order_reviews_dataset ---> Reseñas y calificaciones de clientes.
olist_geolocation_dataset ---> Ubicaciones y códigos postales
product_category_name_translation ---> Traducción de categorías de productos.
*/

use Olist_Ecommerce

--- Misión 1: ¿Cuál es el Ticket Promedio por orden y qué significa para el negocio?
select * from olist_orders_dataset
select * from olist_order_items_dataset

select 
SUM(oid.price) as IngresosTotales,
COUNT(distinct od.order_id) TotalOrdentes,
(SUM(oid.price) / COUNT(distinct od.order_id)) as TicketPromedio
from olist_orders_dataset od
inner join olist_order_items_dataset oid on oid.order_id = od.order_id

--- El cliente gasta en promedio $137.75 por compra, calculado sobre un total de 98,666 órdenes únicas y una
--- facturación de $12,591,643.70

	
/* Misión 2: La gerencia ya sabe cuánto se gasta en promedio por orden ($137.75). 
Ahora quiere saber: ¿Cómo han evolucionado los ingresos y la cantidad de pedidos 
de Olist mes a mes a lo largo del tiempo, y en qué periodos se registraron los picos 
o caídas de ventas más significativos? */

SELECT 
YEAR(order_purchase_timestamp) as AnioDeCompra,
MONTH(order_purchase_timestamp) as MesDeCompra,
ROUND(SUM(oid.price), 2) as IngresosTotales,
COUNT(distinct od.order_id) TotalOrdenes,
ROUND((SUM(oid.price) / COUNT(distinct od.order_id)), 2) as TicketPromedio
FROM olist_orders_dataset od
inner join olist_order_items_dataset oid on oid.order_id = od.order_id
GROUP BY
	YEAR(order_purchase_timestamp),
	MONTH(order_purchase_timestamp)	
ORDER BY
	AnioDeCompra, MesDeCompra ASC;
	
-- Pico más alto: Noviembre de 2017 ($1,010,271.37) y Caída más relevante: Diciembre de 2016 ($10.9)


/*
Misión 3:¿Cuáles son las 10 categorías de productos más vendidas (en cantidad de productos) y 
cuánto dinero aportó cada una al total facturado?
*/
select * from olist_order_items_dataset
select * from olist_products_dataset
select * from product_category_name_translation

SELECT TOP 10
tr.column1 as Categoria,
ROUND(SUM(oid.price), 2)as TotalFacturado,
COUNT(oid.order_item_id) as TotalUnidadesVendidos
FROM olist_order_items_dataset oid
inner join olist_products_dataset pd ON pd.product_id = oid.product_id
inner join product_category_name_translation tr ON tr.column1 = pd.product_category_name
GROUP BY 
	tr.column1
ORDER BY 
	TotalUnidadesVendidos DESC;

-- Lac categoría que encabeza el top es "cama_mesa_baño). Se recomienda enfocar las campañas publicitarias
-- principales de acuerdo a estas 10 categorías prioritarias.

/*
Misión 4: Métodos de Pago Preferidos
¿Cuáles son los métodos de pago más utilizados en la plataforma, cuánto dinero recauda cada uno 
y cuál es el promedio de cuotas (installments) que eligen los clientes?
*/

select * from olist_order_payments_dataset

SELECT 
payment_type as TipoDePago,
COUNT(distinct order_id) as TotalTransacciones,
SUM(payment_value) as TotalRecaudado,
AVG(payment_installments) as PromedioCuotas
FROM olist_order_payments_dataset
GROUP BY
	payment_type
ORDER BY
	TotalRecaudado DESC;

-- Credi Card es el método de pago más usado en la plataforma. Además, que en la consulta ya muestra
-- el total recaudado y el promedio de cuotas.


/*
Misión 5: Logística y Tiempos de Entrega
El área de operaciones necesita evaluar la precisión de los envíos de Olist. Queremos responder a dos preguntas clave:
1. ¿Cuántos días tarda en promedio un pedido desde que se realiza hasta que llega al cliente?
2. ¿Los envíos están llegando a tiempo o con retraso frente a la fecha estimada prometida al cliente?
*/
select * from olist_orders_dataset

SELECT 
COUNT(olist_orders_dataset.order_id) as Total_Ordenes,
AVG(DATEDIFF(DAY, order_delivered_customer_date, order_estimated_delivery_date)) as Diferencia_Fecha_días,
CASE
	WHEN order_estimated_delivery_date > order_delivered_customer_date THEN 'Entregado a tiempo'
	ELSE 'Entregado con retraso'
END as Estado
FROM olist_orders_dataset
WHERE
	order_status = 'delivered'
	AND order_delivered_customer_date IS NOT NULL
GROUP BY
	CASE
		WHEN order_estimated_delivery_date > order_delivered_customer_date THEN 'Entregado a tiempo'
		ELSE 'Entregado con retraso'
	END

-- 88644 órdenes tardan en entregarse en un promedio de 13 días en un estado de "Entregado a tiempo"
-- a diferencia de los 7826 órdenes restantes que se envía con retraso con un promedio de 8 días.


/*
El área comercial necesita saber en qué Estados de Brasil se concentra la facturación para planificar 
campañas de marketing y logística regional. Queremos responder:
¿Cuáles son los 5 Estados (customer_state) que generan mayor volumen de dinero?
¿Cuántas órdenes se han realizado en cada uno de esos Estados?
*/
select * from olist_orders_dataset
select * from olist_order_items_dataset
select * from olist_customers_dataset

SELECT TOP 5
cd.customer_state,
SUM(oid.price) as Total_Facturado,
COUNT(DISTINCT od.order_id) as Total_Ordenes
FROM olist_orders_dataset od
INNER JOIN olist_customers_dataset cd ON od.customer_id = cd.customer_id
INNER JOIN olist_order_items_dataset oid ON od.order_id = oid.order_id
GROUP BY
	cd.customer_state
ORDER BY
	Total_Facturado DESC;

-- Los 5 estados con mayores montos recaudados son SP, RJ, MG, RS y PR:
-- SP (41,375 órdenes), RJ (12,762), MG (11,544), RS (5,432) y PR (4,998) 


---- PROCEDIMIENTOS ALMACENADOS ----
/*
Objetivo de Negocio:

El área comercial quiere un reporte automático donde el usuario ingrese las siglas de cualquier 
Estado de Brasil (por ejemplo: 'SP', 'RJ', 'MG') y el sistema le devuelva:
El total de ventas registradas en ese Estado.
El número de órdenes únicas atendidas.
El ticket promedio por orden (Total Facturado / Total Ordenes).
*/
select * from olist_orders_dataset
select * from olist_order_items_dataset
select * from olist_customers_dataset
;GO

CREATE OR ALTER PROCEDURE sp_Reporte_Ventas_Por_Estado
	@Estado varchar (10)
AS
BEGIN
	SELECT
	cd.customer_state AS Estado,
	ROUND(SUM(oid.price), 2) AS Total_Ventas,
	COUNT(DISTINCT od.order_id) AS Ordenes_Unicas_Atendidas,
	ROUND(SUM(oid.price)/COUNT(DISTINCT od.order_id), 2) as Ticket_Promedio
	FROM olist_orders_dataset od
	INNER JOIN olist_order_items_dataset oid ON od.order_id = oid.order_id
	INNER JOIN olist_customers_dataset cd ON od.customer_id = cd.customer_id
	WHERE
		od.order_status = 'delivered'
		AND
		cd.customer_state = @Estado
	GROUP BY
		cd.customer_state
END;

EXEC sp_Reporte_Ventas_Por_Estado @Estado = 'SP';
EXEC sp_Reporte_Ventas_Por_Estado @Estado = 'RJ';


/*
Contexto de Negocio:
El área financiera requiere un procedimiento almacenado llamado sp_Reporte_Ventas_Por_Ano para 
consultar el rendimiento económico de la plataforma según el año de compra.
Reglas del Reto:
Parámetro de entrada: Debe recibir un número entero que represente el año a consultar (ejemplo: 2017).
Filtro operacional: Considerar únicamente las órdenes con estado entregado (delivered).
Métricas a mostrar en la salida:
- Año de la consulta.
- Total facturado en dinero.
- Cantidad de órdenes únicas.
- Ticket promedio por orden.
*/
select * from olist_orders_dataset
select * from olist_order_items_dataset

CREATE OR ALTER PROCEDURE sp_Reporte_Ventas_Por_Ano
	@Anio int
AS
BEGIN
	SELECT
	YEAR(od.order_purchase_timestamp) AS Anio,
	ROUND(SUM(oid.price), 2) AS Total_Facturado,
	COUNT(DISTINCT od.order_id) AS Ordenes_Unicas,
	ROUND(SUM(oid.price)/COUNT(DISTINCT od.order_id), 2) AS Ticket_Promedio
	FROM olist_orders_dataset od
	INNER JOIN olist_order_items_dataset oid ON od.order_id = oid.order_id
	WHERE
		YEAR(od.order_purchase_timestamp) = @Anio
		AND od.order_status = 'delivered'
	GROUP BY
		YEAR(od.order_purchase_timestamp)
	ORDER BY
		Anio DESC
END;

EXEC sp_Reporte_Ventas_Por_Ano @Anio = 2017;

/*
Objetivo de Negocio:
El departamento de alianzas comerciales necesita auditar la actividad de sus vendedores en la 
plataforma. Requieren un procedimiento almacenado llamado sp_Reporte_Rendimiento_Vendedor para 
evaluar el impacto económico y el alcance de un vendedor específico ingresando su identificador.
Métricas a Mostrar:
-- ID del Vendedor.
-- Total Facturado en ventas.
-- Cantidad de artículos/productos vendidos en total.
-- Cantidad de órdenes únicas gestionadas.
-- Fecha de la primera venta registrada en la plataforma.
-- Fecha de la última venta registrada en la plataforma.
*/
select * from olist_order_items_dataset
select * from olist_orders_dataset

CREATE OR ALTER PROCEDURE sp_Reporte_Rendimiento
	@SellerID varchar(50)
AS
BEGIN
	SELECT
	oid.seller_id,
	SUM(oid.price) AS Total_Facturado,
	COUNT(oid.order_item_id) AS Productos_Total_Vendido,
	COUNT(DISTINCT od.order_id) AS Ordenes_Unicas,
	MIN(od.order_purchase_timestamp) AS Primera_Venta,
	MAX(od.order_purchase_timestamp) AS Ultima_Venta
	FROM olist_orders_dataset od
	INNER JOIN olist_order_items_dataset oid ON od.order_id = oid.order_id
	WHERE
		od.order_status = 'delivered'
		AND oid.seller_id = @SellerID
	GROUP BY
		oid.seller_id
END;

SELECT TOP 1 seller_id FROM olist_order_items_dataset;
EXEC sp_Reporte_Rendimiento @SellerID = '48436dade18ac8b2bce089ec2a041202';

/*
El director de operaciones quiere auditar el impacto de los retrasos logísticos en periodos 
específicos (por ejemplo, durante campañas de Cyber Monday o fechas festivas). Necesitamos un 
procedimiento almacenado llamado sp_Reporte_Demoras_Por_Fecha que analice el desempeño dentro de 
una ventana de tiempo.
Métricas a Mostrar:
- Total de Órdenes Entregadas: Conteo general de pedidos en el periodo.
- Órdenes con Retraso: Conteo de pedidos donde la fecha real de entrega superó la fecha límite estimada.
- Promedio de Días de Retraso: Días promedio de demora en los envíos que llegaron tarde.
*/
select * from olist_orders_dataset

CREATE OR ALTER PROCEDURE sp_Reporte_Demoras_Por_Fecha
	@FechaInicio date,
	@FechaFin date
AS	
BEGIN
	SELECT
	COUNT(olist_orders_dataset.order_id) as Total_Ordenes_Entregados,
	COUNT(CASE
		WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Entregado con retraso'
	END) AS Órdenes_Retrasados,
	AVG(CASE
			WHEN order_estimated_delivery_date > order_delivered_customer_date
			THEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date)
		END) AS Promedio_Dias_Retraso
	FROM olist_orders_dataset
	WHERE 
		olist_orders_dataset.order_status = 'delivered'
		AND CAST (order_purchase_timestamp AS DATE) BETWEEN  @FechaInicio AND @FechaFin
END;

EXEC sp_Reporte_Demoras_Por_Fecha 
    @FechaInicio = '2017-01-01', 
    @FechaFin = '2017-06-30';

/*
El departamento de auditoría necesita un procedimiento almacenado llamado sp_Reporte_Ventas_Por_Rango_Monto 
para analizar el volumen de compras dentro de un rango de montos facturados (por ejemplo, buscar 
ventas de menor valor entre $10 y $50, o compras corporativas entre $500 y $5000).
*/
select * from olist_orders_dataset
select * from olist_order_items_dataset

CREATE OR ALTER PROCEDURE sp_Reporte_Ventas_Por_Rango_Monto
	@MontoMinimo DECIMAL(10,2),
	@MontoMaximo DECIMAL(10,2)
AS
BEGIN
	IF @MontoMinimo < 0 OR @MontoMaximo < 0
		THROW 50001, 'Los montos no pueden ser valores negativos.', 1;

	IF @MontoMinimo > @MontoMaximo
		THROW 50002, 'El monto mínimo no puede ser mayor al monto máximo.', 1;
	SELECT
	od.order_id,
	ROUND(SUM(oid.price), 2) AS Monto_Total_Facturado,
	COUNT(oid.order_item_id) AS Cantidad_Productos
	FROM olist_orders_dataset od
	INNER JOIN olist_order_items_dataset oid ON od.order_id = oid.order_id
	WHERE
		od.order_status = 'delivered'
	GROUP BY
		od.order_id
	HAVING
		ROUND(SUM(oid.price), 2) BETWEEN @MontoMinimo AND @MontoMaximo
END;

EXEC sp_Reporte_Ventas_Por_Rango_Monto @MontoMinimo = 100.00, @MontoMaximo = 200.00;



---- VISTAS (VIEW) ----
/*
Misión 1: El equipo de operaciones necesita una vista llamada vw_Rendimiento_Logistico_Estado 
para monitorear el desempeño de las entregas por cada Estado de Brasil de forma permanente.
*/
CREATE OR ALTER VIEW vw_Rendimiento_Logistico_Estado
AS
SELECT 
    cd.customer_state AS Estado,
    COUNT(od.order_id) AS Total_Ordenes,
    SUM(CASE 
        WHEN od.order_delivered_customer_date <= od.order_estimated_delivery_date THEN 1 
        ELSE 0 
    END) AS Ordenes_A_Tiempo,
    SUM(CASE 
        WHEN od.order_delivered_customer_date > od.order_estimated_delivery_date THEN 1 
        ELSE 0 
    END) AS Ordenes_Con_Retraso,
	CAST(
		ROUND(
			(SUM(CASE WHEN od.order_delivered_customer_date <= od.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0) 
			/ NULLIF(COUNT(od.order_id), 0), 2
			) AS DECIMAL(5,2)
		) AS Porcentaje_A_Tiempo

FROM olist_orders_dataset od
INNER JOIN olist_customers_dataset cd ON od.customer_id = cd.customer_id
WHERE od.order_status = 'delivered'
  AND od.order_delivered_customer_date IS NOT NULL
  AND od.order_estimated_delivery_date IS NOT NULL
GROUP BY cd.customer_state;
GO

-- Ejecutamos la vista para ver los estados con menor porcentaje de entregas a tiempo
SELECT * 
FROM vw_Rendimiento_Logistico_Estado
ORDER BY Porcentaje_A_Tiempo ASC;


/*
Misión 2:
El equipo de finanzas necesita una vista llamada vw_Analisis_Metodos_Pago que sirva para analizar 
cómo prefieren pagar los clientes y el nivel de riesgo/cuotas asociadas a cada método.
*/
select * from olist_order_payments_dataset
select * from olist_orders_dataset

CREATE OR ALTER VIEW vw_Analisis_Metodos_Pago
AS
SELECT
opd.payment_type as Tipo_Pago,
ROUND(SUM(opd.payment_value), 2) as Monto_Total_Metodo,
COUNT(DISTINCT opd.order_id) as Compras_Unicas,
ROUND(AVG(opd.payment_installments), 2) as Promedio_Cuotas,
ROUND(AVG(opd.payment_value), 2) as Monto_Promedio_Transaccion
FROM olist_order_payments_dataset opd
INNER JOIN olist_orders_dataset od ON opd.order_id = od.order_id
WHERE
	od.order_status = 'delivered'
GROUP BY
	opd.payment_type;

SELECT * 
FROM vw_Analisis_Metodos_Pago
ORDER BY Monto_Total_Metodo DESC;


/*
Misión 3: Vista de Auditoría Logística y Tiempos de Entrega
Objetivo de Negocio:
El equipo de logística necesita una vista llamada vw_Tiempos_Entrega_Vendedores para analizar 
cuánto tardan los envíos desde que el cliente compra hasta que el paquete se entrega, además de 
medir el tiempo que toma el vendedor en despachar el paquete a la empresa transportista.
*/
select * from olist_orders_dataset
select * from olist_order_items_dataset

CREATE OR ALTER VIEW vw_Tiempos_Entrega_Vendedores
AS
SELECT
oid.seller_id as Codigo_Vendedor,
COUNT(DISTINCT od.order_id) as Total_Envios,
CAST(AVG(DATEDIFF(DAY, od.order_purchase_timestamp, od.order_delivered_carrier_date)) AS DECIMAl(5, 2)) as Dias_Promedio_Despacho,
CAST(AVG(DATEDIFF(DAY, od.order_purchase_timestamp, od.order_delivered_customer_date)) AS DECIMAL(5, 2)) as Dias_Promedio_Entrega_Total
FROM olist_orders_dataset od
INNER JOIN olist_order_items_dataset oid ON od.order_id = oid.order_id
WHERE
	od.order_status = 'delivered'
	AND od.order_delivered_carrier_date IS NOT NULL
	AND od.order_purchase_timestamp IS NOT NULL
	AND od.order_delivered_customer_date IS NOT NULL
GROUP BY
	oid.seller_id;

SELECT
*
FROM vw_Tiempos_Entrega_Vendedores
ORDER BY Total_Envios DESC;


/*
Misión 4: Vista de Análisis Geográfico de Clientes
El área de Expansión Comercial necesita una vista llamada vw_Analisis_Clientes_Estado para evaluar 
la densidad de la base de clientes y la tasa de concentración de ventas por cada Estado de Brasil.
*/

select * from olist_customers_dataset
select * from olist_orders_dataset

CREATE OR ALTER VIEW vw_Analisis_Clientes_Estado
AS
SELECT
cd.customer_state as Estado,
COUNT(DISTINCT cd.customer_unique_id) as Total_Clientes_Unicos,
COUNT(DISTINCT od.order_id) as Total_Ordenes,
CAST(COUNT(DISTINCT od.order_id) * 1.0 / COUNT(DISTINCT cd.customer_unique_id) AS DECIMAL (5,2) )  as Promedio_Ordenes_Por_Cliente
FROM olist_customers_dataset cd
INNER JOIN olist_orders_dataset od ON cd.customer_id = od.customer_id
WHERE 
	od.order_status = 'delivered'
GROUP BY
	cd.customer_state;

SELECT
*
FROM vw_Analisis_Clientes_Estado
ORDER BY Total_Ordenes DESC;