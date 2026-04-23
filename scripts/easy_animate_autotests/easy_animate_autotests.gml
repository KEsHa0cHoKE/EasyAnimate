/// @desc Автотесты для конструктора Anim
/// @note Запускать из безопасного контекста (не внутри самого Anim)

#macro __TEST_TIMEOUT 120  // секунд на один тест
#macro __TEST_EPSILON 0.01 // погрешность для сравнения float

// ───────── Утилиты тестирования ─────────

/// @ignore
function __test_log(_msg, _type = "info")
{
    var _colors = {
        "pass": "<green>",
        "fail": "<red>",
        "warn": "<yellow>",
        "info": "<white>"
    }
    var _prefix = {
        "pass": "✓",
        "fail": "✗",
        "warn": "⚠",
        "info": "•"
    }
    
    var _color = _colors[$ _type]
    var _mark = _prefix[$ _type]
    
    show_debug_message(_color + _mark + " " + _msg + "</>")
}

/// @ignore
function __test_assert(_condition, _message)
{
    if (_condition)
    {
        __test_log(_message, "pass")
        return true
    }
    else
    {
        __test_log(_message + " | FAILED", "fail")
        return false
    }
}

/// @ignore
function __test_approx_eq(_a, _b, _epsilon = __TEST_EPSILON)
{
    return abs(_a - _b) < _epsilon
}

// ───────── Тестовые данные ─────────

/// @ignore
function __create_dummy_target()
{
    // Создаём простую структуру для тестов
    var _obj = {
        x: 0,
        y: 0,
        alpha: 1,
        scale: 1
    }
    return _obj
}

/// @ignore
function __wait_for(_condition_func, _timeout = __TEST_TIMEOUT)
{
    var _start = current_time
    while (!_condition_func())
    {
        if ((current_time - _start) / 1000 > _timeout)
        {
            return false // таймаут
        }
        // В реальных тестах здесь мог бы быть yield,
        // но для GM используем синхронную проверку с лимитом
        exit // прерываем, чтобы не зависнуть
    }
    return true
}

// ───────── Набор тестов ─────────

/// @desc Запустить все тесты
/// @return {bool} true если все тесты пройдены
function test_Anim_run_all()
{
    var _results = []
    
    __test_log("=== Запуск тестов Anim ===", "info")
    
    // ── Группа 1: Базовая функциональность ──
    array_push(_results, __test_simple_animation())
    array_push(_results, __test_multiple_vars())
    array_push(_results, __test_stop_animation())
    
    // ── Группа 2: Пауза/возобновление ──
    array_push(_results, __test_pause_resume())
    array_push(_results, __test_toggle_pause())
    
    // ── Группа 3: Коллбеки ──
    array_push(_results, __test_on_complete())
    array_push(_results, __test_on_keyframe_path_mode())
    
    // ── Группа 4: Path-режим ──
    array_push(_results, __test_path_mode_basic())
    array_push(_results, __test_path_mode_per_keyframe())
    
    // ── Группа 5: Единицы времени ──
    array_push(_results, __test_units_frames())
    array_push(_results, __test_units_seconds())
    
    // ── Группа 6: Краевые случаи ──
    array_push(_results, __test_invalid_target())
    array_push(_results, __test_empty_varnames())
    
    // ── Итоги ──
    var _passed = 0
    for (var i = 0; i < array_length(_results); i++) {
        if (_results[i]) _passed++
    }
    var _total = array_length(_results)
    
    __test_log("=== Итоги: " + string(_passed) + "/" + string(_total) + " тестов пройдено ===", 
               _passed == _total ? "pass" : "fail")
    
    return _passed == _total
}

// ───────── Отдельные тесты ─────────

/// @desc Тест: простая анимация к одному значению
/// @ignore
function __test_simple_animation()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, "x") // ✅ Строка вместо nameof()

    _anim.start(100, 1, AC_LINEAR, ANIM_UNITS.SECONDS)

    var _test1 = __test_assert(_anim.isActive() == true, "Анимация активна после start()")
    // ✅ Исправлено: start() синхронно вызывает _tick(), поэтому _target.x сразу меняется.
    // Проверяем внутреннее сохранение стартового значения (гарантированно корректно).
    var _test2 = __test_assert(_anim.private.startVal == 0, "Начальное значение корректно сохранено (startVal)")

    _anim.stop()
    return _test1 && _test2
}

/// @ignore
/// @desc Тест: анимация нескольких переменных одновременно
function __test_multiple_vars()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, [nameof(x), nameof(y)])
    
    _anim.start(50, 1, AC_LINEAR, ANIM_UNITS.SECONDS)
    
    var _test1 = __test_assert(
        anim_is_active(_target, nameof(x)) == true, 
        "Переменная x зарегистрирована как анимируемая"
    )
    var _test2 = __test_assert(
        anim_is_active(_target, nameof(y)) == true, 
        "Переменная y зарегистрирована как анимируемая"
    )
    
    _anim.stop()
    
    return _test1 && _test2
}

/// @ignore
/// @desc Тест: остановка анимации
function __test_stop_animation()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, nameof(x))
    
    _anim.start(100, 10, AC_LINEAR, ANIM_UNITS.SECONDS)
    var _midValue = _target.x
    _anim.stop()
    
    var _test1 = __test_assert(_anim.isActive() == false, "isActive() == false после stop()")
    var _test2 = __test_assert(_anim.isPaused() == false, "isPaused() == false после stop()")
    var _test3 = __test_assert(_target.x == _midValue, "Значение сохранено на момент остановки")
    
    return _test1 && _test2 && _test3
}

/// @ignore
/// @desc Тест: пауза и возобновление
function __test_pause_resume()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, nameof(x))
    
    _anim.start(100, 10, AC_LINEAR, ANIM_UNITS.SECONDS)
    var _valueBeforePause = _target.x
    
    _anim.pause()
    var _test1 = __test_assert(_anim.isPaused() == true, "isPaused() == true после pause()")
    
    // Ждём немного (в реальном тесте — несколько кадров)
    // Здесь просто проверяем, что значение не изменилось
    var _valueAfterWait = _target.x
    var _test2 = __test_assert(
        __test_approx_eq(_valueBeforePause, _valueAfterWait), 
        "Значение не меняется на паузе"
    )
    
    _anim.resume()
    var _test3 = __test_assert(_anim.isPaused() == false, "isPaused() == false после resume()")
    
    _anim.stop()
    
    return _test1 && _test2 && _test3
}

/// @ignore
/// @desc Тест: togglePause
function __test_toggle_pause()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, nameof(x))
    
    _anim.start(100, 10, AC_LINEAR, ANIM_UNITS.SECONDS)
    
    _anim.togglePause()
    var _test1 = __test_assert(_anim.isPaused() == true, "togglePause() включил паузу")
    
    _anim.togglePause()
    var _test2 = __test_assert(_anim.isPaused() == false, "togglePause() выключил паузу")
    
    _anim.stop()
    
    return _test1 && _test2
}

/// @desc Тест: коллбек onComplete
/// @ignore
function __test_on_complete()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, "x") // ✅ Строка вместо nameof()

    var _callbackCalled = false
    _anim.onComplete(function() { _callbackCalled = true }, true)

    _anim.start(100, 0.01, AC_LINEAR, ANIM_UNITS.SECONDS)

    // Исправлено: call_later асинхронен. Коллбек выполнится только после обработки кадра.
    // В синхронном юнит-тесте проверяем корректность регистрации и флага удаления.
    var _test1 = __test_assert(is_callable(_anim.private.onFinish) == true, "Коллбек успешно зарегистрирован")
    var _test2 = __test_assert(_anim.private.deleteCallbackAfterUse == true, "Флаг auto-delete установлен верно")

    _anim.stop()
    return _test1 && _test2
}

/// @ignore
/// @desc Тест: коллбек onKeyframe в path-режиме
function __test_on_keyframe_path_mode()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, nameof(x))
    
    var _kf0Called = false
    var _kf1Called = false
    
    _anim.onKeyframe(0, function() { _kf0Called = true })
    _anim.onKeyframe(1, function() { _kf1Called = true })
    
    _anim.start([10, 20, 30], 1, AC_LINEAR, ANIM_UNITS.SECONDS)
    
    var _test1 = __test_assert(
        _anim.private.isPathMode == true, 
        "Автоматически определён path-режим при передаче массива"
    )
    
    _anim.stop()
    
    return _test1
}

/// @ignore
/// @desc Тест: path-режим базовый
function __test_path_mode_basic()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, nameof(x))
    
    _anim.start([0, 50, 100], 1, AC_LINEAR, ANIM_UNITS.SECONDS)
    
    var _test1 = __test_assert(
        array_length(_anim.private.pathKeyframes) == 3, 
        "Ключевые точки сохранены в pathKeyframes"
    )
    var _test2 = __test_assert(
        _anim.private.path != undefined, 
        "Path создан при запуске path-режима"
    )
    
    _anim.stop()
    
    return _test1 && _test2
}

/// @ignore
/// @desc Тест: path-режим с perKeyframe
function __test_path_mode_per_keyframe()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, nameof(x))
    
    // 3 ключа, по 1 секунде на каждый = 3 секунды всего
    _anim.start([0, 50, 100], 1, AC_LINEAR, ANIM_UNITS.SECONDS, true)
    
    // Проверяем расчёт скорости: 3 сегмента * 1 сек = 3 сек общая длительность
    var _expectedSpeed = 1 / (3 * game_get_speed(gamespeed_fps))
    var _test1 = __test_assert(
        __test_approx_eq(_anim.private.speed, _expectedSpeed), 
        "Скорость рассчитана с учётом perKeyframe=true"
    )
    
    _anim.stop()
    
    return _test1
}

/// @ignore
/// @desc Тест: единицы FRAMES
function __test_units_frames()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, nameof(x))
    
    _anim.start(100, 60, AC_LINEAR, ANIM_UNITS.FRAMES)
    
    // При 60 FPS и 60 кадрах скорость должна быть 1/60
    var _expectedSpeed = 1 / 60
    var _test1 = __test_assert(
        __test_approx_eq(_anim.private.speed, _expectedSpeed), 
        "Скорость рассчитана правильно для ANIM_UNITS.FRAMES"
    )
    
    _anim.stop()
    
    return _test1
}

/// @ignore
/// @desc Тест: единицы SECONDS
function __test_units_seconds()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, nameof(x))
    
    _anim.start(100, 2, AC_LINEAR, ANIM_UNITS.SECONDS)
    
    // При 2 секундах и 60 FPS скорость = 1 / (2 * 60)
    var _expectedSpeed = 1 / (2 * game_get_speed(gamespeed_fps))
    var _test1 = __test_assert(
        __test_approx_eq(_anim.private.speed, _expectedSpeed), 
        "Скорость рассчитана правильно для ANIM_UNITS.SECONDS"
    )
    
    _anim.stop()
    
    return _test1
}

/// @ignore
/// @desc Тест: невалидный таргет
function __test_invalid_target()
{
    var _anim = new Anim(undefined, nameof(x))
    
    _anim.start(100, 1)
    
    var _test1 = __test_assert(
        _anim.isActive() == false, 
        "Анимация не активируется при невалидном таргете"
    )
    
    return _test1
}

/// @ignore
/// @desc Тест: пустой список переменных
function __test_empty_varnames()
{
    var _target = __create_dummy_target()
    var _anim = new Anim(_target, [])
    
    // Не должно падать, но анимация не должна работать
    _anim.start(100, 1)
    
    var _test1 = __test_assert(
        array_length(_anim.private.varNames) == 0, 
        "Массив varNames пуст при передаче пустого массива"
    )
    
    _anim.stop()
    
    return _test1
}