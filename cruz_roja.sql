-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 29-07-2025 a las 19:38:04
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `cruz_roja`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `alertas`
--

CREATE TABLE `alertas` (
  `id` int(11) NOT NULL,
  `producto_id` int(11) DEFAULT NULL,
  `tipo_alerta` enum('amarilla','naranja','roja') DEFAULT NULL,
  `fecha_alerta` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `alertas`
--

INSERT INTO `alertas` (`id`, `producto_id`, `tipo_alerta`, `fecha_alerta`) VALUES
(5, 19, 'roja', '2025-07-24'),
(6, 20, 'roja', '2025-07-24'),
(7, 21, 'roja', '2025-07-24'),
(8, 22, 'naranja', '2025-07-24'),
(9, 23, 'roja', '2025-07-24'),
(10, 24, 'amarilla', '2025-07-24'),
(11, 25, 'amarilla', '2025-07-24');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `devoluciones`
--

CREATE TABLE `devoluciones` (
  `id` int(11) NOT NULL,
  `producto_id` int(11) DEFAULT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `lote` varchar(50) DEFAULT NULL,
  `proveedor` varchar(100) DEFAULT NULL,
  `fecha_devolucion` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historial_eliminados`
--

CREATE TABLE `historial_eliminados` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `lote` varchar(50) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `fecha_caducidad` date DEFAULT NULL,
  `motivo` varchar(50) DEFAULT NULL,
  `fecha_eliminacion` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `historial_eliminados`
--

INSERT INTO `historial_eliminados` (`id`, `nombre`, `lote`, `cantidad`, `fecha_caducidad`, `motivo`, `fecha_eliminacion`) VALUES
(22, 'fklllngjef', '214124', 12, '2025-07-31', 'Eliminado manualmente', '2025-07-29');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logs_devoluciones`
--

CREATE TABLE `logs_devoluciones` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `lote` varchar(100) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `fecha_caducidad` date DEFAULT NULL,
  `fecha_devolucion` date DEFAULT NULL,
  `fecha_reingreso_esperada` date DEFAULT NULL,
  `motivo` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `logs_devoluciones`
--

INSERT INTO `logs_devoluciones` (`id`, `nombre`, `lote`, `cantidad`, `fecha_caducidad`, `fecha_devolucion`, `fecha_reingreso_esperada`, `motivo`) VALUES
(3, 'wefwef', '241241', 12, '2025-07-21', '2025-07-29', '2025-08-01', 'Devuelto por vencimiento o defecto');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `lote` varchar(50) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `fecha_caducidad` date DEFAULT NULL,
  `eliminado` tinyint(1) DEFAULT 0,
  `precio` decimal(10,2) NOT NULL DEFAULT 0.00,
  `promocion_activa` tinyint(1) DEFAULT 0,
  `precio_promocion` decimal(10,2) DEFAULT NULL,
  `proveedor_id` int(11) DEFAULT NULL,
  `producto_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id`, `nombre`, `lote`, `cantidad`, `fecha_caducidad`, `eliminado`, `precio`, `promocion_activa`, `precio_promocion`, `proveedor_id`, `producto_id`) VALUES
(10, 'ambroxol', '23482', 5, '2025-08-25', 1, 0.00, 0, NULL, NULL, NULL),
(19, 'gdfgdfg', '341334', 34, '2025-03-27', 1, 4.00, 0, NULL, NULL, NULL),
(20, 'htrhge', '4234', 34, '2025-07-21', 1, 6.21, 0, NULL, NULL, NULL),
(21, 'wefwef', '241241', 12, '2025-07-21', 1, 6.20, 0, NULL, NULL, NULL),
(22, 'fklllngjef', '214124', 12, '2025-07-31', 1, 4.00, 1, 2.00, NULL, NULL),
(23, 'gwoejgfow', '23123', 12, '2025-07-21', 0, 4.00, 0, NULL, NULL, NULL),
(24, 'bismuto', '102201', 23, '2025-08-04', 1, 23.00, 1, 17.25, NULL, NULL),
(25, 'Quesitrix', '2412', 23, '2025-08-02', 1, 12.00, 1, 9.00, NULL, NULL);

--
-- Disparadores `productos`
--
DELIMITER $$
CREATE TRIGGER `evitar_duplicado_lote` BEFORE INSERT ON `productos` FOR EACH ROW BEGIN
    DECLARE existente_id INT;
    SELECT id INTO existente_id FROM productos
    WHERE nombre = NEW.nombre AND lote = NEW.lote
    LIMIT 1;

    IF existente_id IS NOT NULL THEN
        UPDATE productos
        SET cantidad = cantidad + NEW.cantidad
        WHERE id = existente_id;
        SET NEW.id = NULL;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `evitar_duplicados` BEFORE INSERT ON `productos` FOR EACH ROW BEGIN
  DECLARE existe INT;
  SELECT COUNT(*) INTO existe FROM productos WHERE nombre = NEW.nombre AND lote = NEW.lote;
  IF existe > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Este medicamento con el mismo lote ya está registrado.';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `evitar_medicina_duplicada` BEFORE INSERT ON `productos` FOR EACH ROW BEGIN
  DECLARE cantidad_existente INT;

  SELECT cantidad INTO cantidad_existente
  FROM productos
  WHERE nombre = NEW.nombre AND lote = NEW.lote;

  IF cantidad_existente IS NOT NULL THEN
    -- En vez de insertar duplicado, actualiza la cantidad
    UPDATE productos
    SET cantidad = cantidad + NEW.cantidad
    WHERE nombre = NEW.nombre AND lote = NEW.lote;
    
    -- Cancelar el insert
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medicina ya registrada. Se ha actualizado la cantidad.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `contacto` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `alertas`
--
ALTER TABLE `alertas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `producto_id` (`producto_id`);

--
-- Indices de la tabla `devoluciones`
--
ALTER TABLE `devoluciones`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `historial_eliminados`
--
ALTER TABLE `historial_eliminados`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `logs_devoluciones`
--
ALTER TABLE `logs_devoluciones`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `proveedor_id` (`proveedor_id`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `alertas`
--
ALTER TABLE `alertas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `devoluciones`
--
ALTER TABLE `devoluciones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `historial_eliminados`
--
ALTER TABLE `historial_eliminados`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT de la tabla `logs_devoluciones`
--
ALTER TABLE `logs_devoluciones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `alertas`
--
ALTER TABLE `alertas`
  ADD CONSTRAINT `alertas_ibfk_1` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`);

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `productos_ibfk_1` FOREIGN KEY (`proveedor_id`) REFERENCES `proveedores` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
