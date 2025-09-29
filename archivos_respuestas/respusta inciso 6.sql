WITH movimientos_recientes AS (
    SELECT 
    cliente_Skey,
    SUM(monto) AS total_30dias
    FROM dbr_movimientos_colocacion_riesgo m
    INNER JOIN dm_fecha f ON m.fecha_cierre_Skey = f.fecha_Skey
    WHERE f.fecha >= DATEADD(DAY, -30, GETDATE())  -- últimos 30 días
    GROUP BY cliente_Skey
),
promedio_historico AS (
    SELECT 
    cliente_Skey,
    AVG(monto_mes) AS promedio_historico
    FROM (
        SELECT 
            cliente_Skey,
            f.anio,
            f.mes,
            SUM(monto) AS monto_mes
    FROM dbr_movimientos_colocacion_riesgo m
    INNER JOIN dm_fecha f ON m.fecha_cierre_Skey = f.fecha_Skey
    GROUP BY cliente_Skey, f.anio, f.mes
    ) t
    GROUP BY cliente_Skey
)
SELECT 
r.cliente_Skey,
c.nombre_completo,
r.total_30dias,
h.promedio_historico,
CAST((r.total_30dias*1.0 / h.promedio_historico) * 100 AS DECIMAL(10,2)) AS porcentaje_vs_promedio
FROM movimientos_recientes r
INNER JOIN promedio_historico h ON r.cliente_Skey = h.cliente_Skey
INNER JOIN dm_cliente c ON r.cliente_Skey = c.cliente_Skey
WHERE r.total_30dias > 3 * h.promedio_historico  -- más del 300%
ORDER BY porcentaje_vs_promedio DESC;