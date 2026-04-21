// by KEsHa_cHoKE
// Простая анимация на time_source с поддержкой кривых и экстраполяции

#macro __ANIM_USE_DELTA false

enum ANIM_UNITS {
    FRAMES,
    SECONDS
}

///@desc Конструктор анимации: плавное изменение переменной от текущего значения к целевому
///@param {Id.Instance|struct} target Объект или структура, чью переменную анимировать
///@param {string|array<string>} vars Имя переменной или массив имён (используйте nameof())
function Anim(target, vars) constructor
{
    // ───────── Приватные данные в структуре ─────────
    private = {
        target: undefined,          // Объект/структура для анимации
        varNames: [],              // Имена анимируемых переменных
        timeSource: undefined,     // Handle таймсорса
        
        active: false,             // Идёт ли анимация
        paused: false,             // На паузе ли
        progress: 0,               // Прогресс 0..1
        
        startVal: 0,               // Значение в момент старта
        endVal: 0,                 // Целевое значение
        duration: 1,               // Длительность в выбранных единицах
        mode: ANIM_UNITS.SECONDS,  // Единицы времени
        curve: ANIM_CURVE_LINEAR,  // Кривая анимации
        speed: undefined,          // Рассчитанная скорость прогресса
        
        onFinish: undefined,       // Коллбек по завершении
        deleteCallbackAfterUse: false
    }
    
    
    
    // ───────── Публичный API ─────────
    
    ///@desc Запустить анимацию к целевому значению
    ///@param {real} endValue К чему анимировать
    ///@param {real} duration Длительность (в кадрах или секундах)
    ///@param {Asset.GMAnimCurve} curve Кривая (по умолчанию линейная)
    ///@param {Constant.ANIM_UNITS} mode Тип времени (по умолчанию ANIM_UNITS.SECONDS)
    start = function(endValue, duration, curve = ANIM_CURVE_LINEAR, mode = ANIM_UNITS.SECONDS)
    {
        if (!_isTargetValid()) exit
        
        // Остановить предыдущую анимацию если есть
        if (private.timeSource != undefined) call_cancel(private.timeSource)
        else _registerVars()
        
        // Сброс параметров
        private.active = true
        private.paused = false
        private.progress = 0
        private.speed = undefined
        
        private.endVal = endValue
        private.duration = duration
        private.mode = mode
        private.curve = curve != undefined ? curve : ANIM_CURVE_LINEAR
        private.startVal = _getTargetVarValue()
        
        _tick()
		
		
		return self
    }
    
    ///@desc Остановить анимацию (переменная останется на текущем значении)
    stop = function()
    {
        private.active = false
        private.paused = false
        if (private.timeSource != undefined) call_cancel(private.timeSource)
        private.timeSource = undefined
        _unregisterVars()
		
		
		return self
    }
    
    ///@desc Поставить на паузу
    pause = function()
    {
        if (!private.active) exit
        private.paused = true
        if (private.timeSource != undefined) call_cancel(private.timeSource)
        private.timeSource = undefined
		
		
		return self
    }
    
    ///@desc Снять с паузы
    resume = function()
    {
        if (!private.active || !private.paused) exit
        private.paused = false
        _tick()
		
		
		return self
    }
    
    ///@desc Переключить паузу (удобно для обработчиков ввода)
    togglePause = function() 
    { 
        if (private.paused) resume()
        else pause()
			
		
		return self
    }
    
    ///@desc Вернуть текущий прогресс анимации (0..1)
    getProgress = function() { return private.progress }
    
    ///@desc Активна ли анимация?
    isActive = function() { return private.active }
    
    ///@desc На паузе ли анимация?
    isPaused = function() { return private.paused }
    
    ///@desc Установить коллбек, который выполнится по завершении анимации
    ///@param {function} callback Функция без аргументов
    ///@param {bool} deleteAfterCall Удалить коллбек после вызова (по умолчанию false)
    onComplete = function(callback, deleteAfterCall = false)
    {
        if (!is_callable(callback)) show_error("Anim: onComplete() -> Ожидалась функция", true)
        private.onFinish = callback
        private.deleteCallbackAfterUse = deleteAfterCall
		
		
		return self
    }
    
    ///@desc Очистить коллбек завершения
    clearOnComplete = function() { private.onFinish = undefined; return self }
    
    
    
    // ───────── Приватные методы ─────────
    
    /// @ignore
    _isTargetValid = function() { return instance_exists(private.target) || is_struct(private.target) }
    
    /// @ignore
    _getTargetVarValue = function()
    {
        if (!_isTargetValid()) return 0
        return is_struct(private.target) ? private.target[$ private.varNames[0]] : variable_instance_get(private.target, private.varNames[0])
    }
    
    /// @ignore
    _setTargetVarValue = function(val)
    {
        if (!_isTargetValid()) exit
        for (var i = 0; i < array_length(private.varNames); i++)
        {
            if (is_struct(private.target)) private.target[$ private.varNames[i]] = val
            else variable_instance_set(private.target, private.varNames[i], val)
        }
    }
    
    /// @ignore
    _registerVars = function()
    {
        if (!_isTargetValid()) exit
        var arr = is_struct(private.target) ? private.target[$ __INSTANCE_ANIMATABLE_VARS_NAME] : variable_instance_get(private.target, __INSTANCE_ANIMATABLE_VARS_NAME)
        if (arr == undefined)
        {
            arr = []
            if (is_struct(private.target)) private.target[$ __INSTANCE_ANIMATABLE_VARS_NAME] = arr
            else variable_instance_set(private.target, __INSTANCE_ANIMATABLE_VARS_NAME, arr)
        }
        
        for (var i = 0; i < array_length(private.varNames); i++)
        {
            var name = private.varNames[i]
            if (!array_contains(arr, name)) array_push(arr, name)
        }
    }
    
    /// @ignore
    _unregisterVars = function()
    {
        if (!_isTargetValid()) exit
        var arr = is_struct(private.target) ? private.target[$ __INSTANCE_ANIMATABLE_VARS_NAME] : variable_instance_get(private.target, __INSTANCE_ANIMATABLE_VARS_NAME)
        if (arr == undefined) exit
        
        for (var i = array_length(private.varNames) - 1; i >= 0; i--)
        {
            var name = private.varNames[i]
            var idx = array_get_index(arr, name)
            if (idx != -1) array_delete(arr, idx, 1)
        }
    }
    
    /// @ignore
    _evalCurve = function(t, curve)
    {
        var ch = animcurve_get_channel(curve, 0)
        if (ch == undefined) return t // fallback на линейную, если канал не найден
        return animcurve_channel_evaluate(ch, t)
    }
    
    /// @ignore
    _tick = function()
    {
        if (!private.active || private.paused || !_isTargetValid()) exit
        if (array_length(private.varNames) == 0) show_error("Anim: Не заданы переменные для анимации", true)
        
        // Рассчитать скорость один раз
        if (private.speed == undefined)
        {
            private.speed = (private.mode == ANIM_UNITS.FRAMES) ? 
                1 / private.duration : 
                1 / (private.duration * game_get_speed(gamespeed_fps))
        }
        
        // Обновить прогресс
        var dtMult = __ANIM_USE_DELTA ? (delta_time / game_get_speed(gamespeed_microseconds)) : 1
        private.progress += private.speed * dtMult
        
        // Получить значение из кривой (может быть <0 или >1)
        var curveVal = _evalCurve(private.progress, private.curve)
        
        // Интерполяция с поддержкой экстраполяции (bounce/overshoot)
        var newVal = private.startVal + (private.endVal - private.startVal) * curveVal
        _setTargetVarValue(newVal)
        
        if (private.progress < 1)
        {
            private.timeSource = call_later(1, time_source_units_frames, _tick)
        }
        else
        {
            // Финализация
            _setTargetVarValue(private.endVal)
            private.active = false
            private.paused = false
            private.timeSource = undefined
            _unregisterVars()
            
            if (is_callable(private.onFinish))
            {
                private.onFinish()
                if (private.deleteCallbackAfterUse) private.onFinish = undefined
            }
        }
    }
    
    
    
    // ───────── Инициализация ─────────
    // Добавляем переменные в список анимируемых у целевого объекта
    if (!is_array(vars)) private.varNames = [vars]
    else private.varNames = vars
    
    private.target = target
    _registerVars()
}



/////@desc Проверить, анимируется ли переменная у объекта
/////@param {Id.Instance|Struct} obj Объект для проверки
/////@param {String} varName Имя переменной
/////@return {Bool} true если переменная сейчас анимируется
//function anim_variable_is_animating(obj, varName)
//{
    //if (!is_struct(obj) && !variable_instance_exists(obj, __INSTANCE_ANIMATABLE_VARS_NAME)) return false
    //if (is_struct(obj) && !struct_exists(obj, __INSTANCE_ANIMATABLE_VARS_NAME)) return false
    //
    //var arr = is_struct(obj) ? obj[$ __INSTANCE_ANIMATABLE_VARS_NAME] : variable_instance_get(obj, __INSTANCE_ANIMATABLE_VARS_NAME)
    //return array_contains(arr, varName)
//}