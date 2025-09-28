CREATE DATABASE chn_dw;

USE chn_dw;


-- DIMENSIONES

CREATE TABLE dm_cliente (
    cliente_Skey BIGINT IDENTITY(1,1) PRIMARY KEY,
    cod_cliente VARCHAR(50) NOT NULL UNIQUE,
    tipo_cliente VARCHAR(20) NOT NULL CHECK (tipo_cliente IN ('PERSONA','JURIDICO')), -- SE VERIFICAN QUE DATOS CORRESPONDAN A ESTOS VALORES
    primer_nombre VARCHAR(50) NULL DEFAULT 'PD',
    segundo_nombre VARCHAR(50) NULL  DEFAULT 'PD',
    primer_apellido VARCHAR(50) NULL DEFAULT 'PD',
    segundo_apellido VARCHAR(50) NULL  DEFAULT 'PD',
    nombre_completo VARCHAR(200) NOT NULL,
    dpi VARCHAR(25) NOT NULL UNIQUE, 
    fecha_nacimiento DATE  NOT NULL,
    genero VARCHAR(10) CHECK (genero IN ('M','F','OTRO')),
    segmento_cliente VARCHAR(50) NULL  DEFAULT 'PD',
    fecha_alta DATE NOT NULL,
    fecha_baja DATE NULL DEFAULT ('1999-01-01'),
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('ACTIVO','INACTIVO')),
    es_actual BIT NOT NULL DEFAULT 0,
    vigente_desde DATETIME NOT NULL DEFAULT ('1999-01-01'),
    vigente_hasta DATETIME NULL DEFAULT ('1999-01-01'),
    CONSTRAINT CK_dm_cliente_vigencia CHECK (vigente_hasta IS NULL OR vigente_hasta >= vigente_desde)
);

CREATE INDEX IX_dm_cliente_dpi ON dm_cliente(dpi);
CREATE INDEX IX_dm_cliente_vigencia ON dm_cliente(vigente_desde, vigente_hasta);


CREATE TABLE dm_producto (
    producto_Skey BIGINT IDENTITY(1,1) PRIMARY KEY,
    cod_producto VARCHAR(50) NOT NULL UNIQUE,
    tipo_producto VARCHAR(50) NOT NULL,
    descripcion TEXT NULL DEFAULT 'PD',
    moneda CHAR(3) NOT NULL,
    fecha_apertura DATE NOT NULL,
    estado_producto VARCHAR(20) NOT NULL CHECK (estado_producto IN ('ACTIVO','INACTIVO'))
);


CREATE INDEX IX_dm_producto_codigo ON dm_producto(cod_producto);


CREATE TABLE dm_sucursal (
    sucursal_Skey BIGINT IDENTITY(1,1) PRIMARY KEY,
    cod_agencia VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    region VARCHAR(100) NULL DEFAULT 'PD',
    direccion VARCHAR(200) NULL DEFAULT 'PD'
);


CREATE TABLE dm_fecha (
    fecha_Skey INT PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    anio INT NOT NULL,
    mes INT NOT NULL CHECK (mes BETWEEN 1 AND 12),
    dia INT NOT NULL CHECK (dia BETWEEN 1 AND 31),
    trimestre INT NOT NULL CHECK (trimestre BETWEEN 1 AND 4),
    dia_semana INT NOT NULL CHECK (dia_semana BETWEEN 1 AND 7)
);

CREATE INDEX IX_dm_fecha_anio_mes ON dm_fecha(anio, mes);


CREATE TABLE dm_clasificacion_riesgo (
    clasificacion_riesgo_Skey BIGINT IDENTITY(1,1) PRIMARY KEY,
    codigo_riesgo VARCHAR(20) NOT NULL UNIQUE,
    descripcion VARCHAR(200) NOT NULL,
    porcentaje_provision DECIMAL(5,4) NOT NULL CHECK (porcentaje_provision BETWEEN 0 AND 1),
    vigente_desde DATE NOT NULL,
    vigente_hasta DATE NULL DEFAULT ('1999-01-01'),
    CONSTRAINT CK_dm_clasifRiesgo_vigencia CHECK (vigente_hasta IS NULL OR vigente_hasta >= vigente_desde)
);


CREATE TABLE dm_modelo_evaluacion (
    modelo_Skey BIGINT IDENTITY(1,1) PRIMARY KEY,
    nombre_modelo VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    fecha_entrenamiento DATE NOT NULL
);


CREATE TABLE dm_colocacion (
    fac_colocacion_Skey BIGINT IDENTITY(1,1) PRIMARY KEY,
    cod_col_cartera VARCHAR(50) NOT NULL UNIQUE,
    tipo_prestamo VARCHAR(50) NOT NULL,
    moneda CHAR(3) NOT NULL,
    fecha_apertura DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    tasa_interes DECIMAL(6,3) NOT NULL CHECK (tasa_interes >= 0),
    estado_prestamo VARCHAR(20) NOT NULL CHECK (estado_prestamo IN ('VIGENTE','COBRO ADMINISTRATIVO','EN PRORROGA','COBRO JUDICIAL','CANCELADO','ANULADO'))
);


CREATE INDEX IX_dm_colocacion_estado ON dm_colocacion(estado_prestamo);


--   TABLAS DE HECHOS


CREATE TABLE dbr_colocacion_riesgo (
    fac_colocacion_Skey BIGINT IDENTITY(1,1) PRIMARY KEY,
    fecha_cierre_Skey INT NOT NULL,
    cliente_Skey BIGINT NOT NULL,
    producto_Skey BIGINT NOT NULL,
    prestamo_Skey BIGINT NOT NULL,
    agencia_Skey BIGINT NOT NULL,
    riesgo_Skey BIGINT NOT NULL,
    saldo_capital DECIMAL(18,2) NOT NULL,
    dias_mora INT NOT NULL CHECK (dias_mora >= 0),
    capital_vencido DECIMAL(18,2) NOT NULL DEFAULT 0,
    monto_provision DECIMAL(18,2) NOT NULL DEFAULT 0,
    prob_incumplimiento DECIMAL(5,4) NULL CHECK (prob_incumplimiento BETWEEN 0 AND 1),
    perdida_incumplimiento DECIMAL(5,4) NULL CHECK (perdida_incumplimiento BETWEEN 0 AND 1),
    CONSTRAINT FK_dbrColRiesgo_fecha FOREIGN KEY (fecha_cierre_Skey) REFERENCES dm_fecha(fecha_Skey),
    CONSTRAINT FK_dbrColRiesgo_cliente FOREIGN KEY (cliente_Skey) REFERENCES dm_cliente(cliente_Skey),
    CONSTRAINT FK_dbrColRiesgo_producto FOREIGN KEY (producto_Skey) REFERENCES dm_producto(producto_Skey),
    CONSTRAINT FK_dbrColRiesgo_prestamo FOREIGN KEY (prestamo_Skey) REFERENCES dm_colocacion(fac_colocacion_Skey),
    CONSTRAINT FK_dbrColRiesgo_agencia FOREIGN KEY (agencia_Skey) REFERENCES dm_sucursal(sucursal_Skey),
    CONSTRAINT FK_dbrColRiesgo_riesgo FOREIGN KEY (riesgo_Skey) REFERENCES dm_clasificacion_riesgo(clasificacion_riesgo_Skey)
);

CREATE INDEX IX_dbr_colocacion_riesgo_fecha ON dbr_colocacion_riesgo(fecha_cierre_Skey);
CREATE INDEX IX_dbr_colocacion_riesgo_cliente ON dbr_colocacion_riesgo(cliente_Skey);
CREATE INDEX IX_dbr_colocacion_riesgo_estado_mora ON dbr_colocacion_riesgo(dias_mora, saldo_capital);


CREATE TABLE dbr_movimientos_colocacion_riesgo (
    movimiento_Skey BIGINT IDENTITY(1,1) PRIMARY KEY,
    fecha_cierre_Skey INT NOT NULL,
    cliente_Skey BIGINT NOT NULL,
    producto_Skey BIGINT NOT NULL,
    sucursal_Skey BIGINT NOT NULL,
    tipo_transaccion VARCHAR(50) NOT NULL,
    monto DECIMAL(18,2) NOT NULL,
    saldo_posterior DECIMAL(18,2) NOT NULL,
    moneda CHAR(3) NOT NULL,
    canal VARCHAR(50) NULL DEFAULT 'PD',
    CONSTRAINT FK_dbrMovRiesgo_fecha FOREIGN KEY (fecha_cierre_Skey) REFERENCES dm_fecha(fecha_Skey),
    CONSTRAINT FK_dbrMovRiesgo_cliente FOREIGN KEY (cliente_Skey) REFERENCES dm_cliente(cliente_Skey),
    CONSTRAINT FK_dbrMovRiesgo_producto FOREIGN KEY (producto_Skey) REFERENCES dm_producto(producto_Skey),
    CONSTRAINT FK_dbrMovRiesgo_sucursal FOREIGN KEY (sucursal_Skey) REFERENCES dm_sucursal(sucursal_Skey)
);

CREATE INDEX IX_dbr_movimientos_fecha_sucursal ON dbr_movimientos_colocacion_riesgo(fecha_cierre_Skey, sucursal_Skey);


CREATE TABLE dbr_evaluacion (
    evaluacion_Skey BIGINT IDENTITY(1,1) PRIMARY KEY,
    fecha_evaluacion_Skey INT NOT NULL,
    cliente_Skey BIGINT NOT NULL,
    producto_Skey BIGINT NOT NULL,
    modelo_Skey BIGINT NOT NULL,
    score DECIMAL(8,4) NOT NULL,
    prob_default DECIMAL(5,4) NOT NULL CHECK (prob_default BETWEEN 0 AND 1),
    evaluador VARCHAR(100) NULL DEFAULT 'PD' ,
    observaciones TEXT NULL DEFAULT 'PD',
    accion_recomendada VARCHAR(200) NULL DEFAULT 'PD',
    CONSTRAINT FK_dbrEval_fecha FOREIGN KEY (fecha_evaluacion_Skey) REFERENCES dm_fecha(fecha_Skey),
    CONSTRAINT FK_dbrEval_cliente FOREIGN KEY (cliente_Skey) REFERENCES dm_cliente(cliente_Skey),
    CONSTRAINT FK_dbrEval_producto FOREIGN KEY (producto_Skey) REFERENCES dm_producto(producto_Skey),
    CONSTRAINT FK_dbrEval_modelo FOREIGN KEY (modelo_Skey) REFERENCES dm_modelo_evaluacion(modelo_Skey)
);

CREATE INDEX IX_dbr_evaluacion_modelo_fecha ON dbr_evaluacion(modelo_Skey, fecha_evaluacion_Skey);