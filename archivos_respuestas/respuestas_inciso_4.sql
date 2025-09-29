-- Listar todos los clientes con productos en mora.
SELECT dc.cod_cliente,
dp.tipo_producto,
dp.descripcion,
dbcr.dias_mora,
dbcr.prestamo_Skey
FROM chn_dw.dbo.dbr_colocacion_riesgo dbcr
LEFT JOIN chn_dw.dbo.dm_cliente dc ON dc.cliente_Skey = dbcr.cliente_Skey
LEFT JOIN chn_dw.dbo.dm_producto dp ON dp.producto_Skey = dbcr.producto_Skey
WHERE dias_mora > 0 
ORDER BY dc.cod_cliente;


-- Calcular el saldo total por tipo de cliente (individual vs jurídico).

SELECT
dc.tipo_cliente,
SUM(dbcr.saldo_capital) AS saldo_total
FROM chn_dw.dbo.dbr_colocacion_riesgo dbcr
LEFT JOIN chn_dw.dbo.dm_cliente dc ON dc.cliente_Skey = dbcr.cliente_Skey
GROUP BY dc.tipo_cliente;


-- Mostrar el histórico de clasificaciones de riesgo de un cliente específico.
SELECT  dc.cod_cliente,
dc.nombre_completo,
df.fecha AS fecha_evaluacion,
dev.score,
dev.prob_default,
dev.evaluador,
dev.observaciones,
dev.accion_recomendada
FROM chn_dw.dbo.dbr_evaluacion dev
LEFT JOIN chn_dw.dbo.dm_fecha df ON df.fecha_Skey = dev.fecha_evaluacion_Skey
LEFT JOIN chn_dw.dbo.dm_cliente dc ON dc.cliente_Skey = dev.cliente_Skey
WHERE dc.cod_cliente = 7449522859 
ORDER BY df.fecha ASC;