WITH saldo_mensual AS (
    SELECT 
    cr.cliente_Skey,
    cli.nombre_completo,
    p.descripcion AS producto,
    r.descripcion AS clasificacion_riesgo,
    f.anio,
    f.mes,
    SUM(cr.saldo_capital) AS saldo_mensual
    FROM dbr_colocacion_riesgo cr
    INNER JOIN dm_cliente cli ON cr.cliente_Skey = cli.cliente_Skey
    INNER JOIN dm_producto p ON cr.producto_Skey = p.producto_Skey
    INNER JOIN dm_clasificacion_riesgo r ON cr.riesgo_Skey = r.clasificacion_riesgo_Skey
    INNER JOIN dm_fecha f ON cr.fecha_cierre_Skey = f.fecha_Skey
    GROUP BY cr.cliente_Skey, cli.nombre_completo, p.descripcion, r.descripcion, f.anio, f.mes
),
crecimiento AS (
    SELECT 
        cliente_Skey,
        nombre_completo,
        producto,
        clasificacion_riesgo,
        anio,
        mes,
        saldo_mensual,
        LAG(saldo_mensual) OVER (PARTITION BY cliente_Skey ORDER BY anio, mes) AS saldo_anterior,
        CASE WHEN LAG(saldo_mensual) OVER (PARTITION BY cliente_Skey ORDER BY anio, mes) = 0 
        THEN NULL
         ELSE (saldo_mensual - LAG(saldo_mensual) OVER (PARTITION BY cliente_Skey ORDER BY anio, mes)) * 1.0 / LAG(saldo_mensual) OVER (PARTITION BY cliente_Skey ORDER BY anio, mes) * 100
        END AS crecimiento_pct
    FROM saldo_mensual
),
saldo_total_cliente AS (
    SELECT 
    cliente_Skey,
    nombre_completo,
    producto,
    clasificacion_riesgo,
    SUM(saldo_mensual) AS saldo_total,
    AVG(crecimiento_pct) AS crecimiento_promedio
    FROM crecimiento
    GROUP BY cliente_Skey, nombre_completo, producto, clasificacion_riesgo
)
SELECT TOP 10 *
FROM saldo_total_cliente
ORDER BY saldo_total DESC;