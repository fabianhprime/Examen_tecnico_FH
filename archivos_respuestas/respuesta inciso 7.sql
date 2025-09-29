-- 7. Optimización de Query Optimiza esta consulta y sugiere índices:
SELECT c.nombre,
p.tipo_producto,
t.fecha,
t.monto
FROM transacciones t
LEFT JOIN productos p ON p.producto_id = t.producto_id
LEFT JOIN clientes c ON c.cliente_id = p.cliente_id
WHERE t.fecha >= '2024-01-01' 
	AND t.monto > 5000
ORDER BY t.fecha DESC

-- SUGERENCIA INDICE PRODUCTO
CREATE INDEX idx_productos_clienteid ON productos (cliente_id);
CREATE INDEX idx_transacciones_productoid ON transacciones (producto_id);