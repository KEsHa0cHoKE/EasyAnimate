# Easy Animate — Анимация переменных

Простая, легковесная и мощная система анимации переменных для GameMaker Studio 2.3+. Позволяет плавно изменять любые числовые свойства объектов и структур, используя встроенные time_source, кривые анимации и режим ключевых кадров.

---

[Репозиторий](https://github.com/KEsHa0cHoKE/Animation-Handle)

---

## 🚀 Быстрый старт

```gml
// 1. Анимация одной переменной к целевому значению
var anim = new Anim(self, nameof(x));
anim.start(500, 1.5, AC_ELASTIC, ANIM_UNITS.SECONDS);

// 2. Анимация нескольких переменных одновременно
var anim2 = new Anim(self, [nameof(image_xscale), nameof(image_yscale)]);
anim2.start(200, 0.5, AC_BOUNCE, ANIM_UNITS.FRAMES);

// 3. Анимация по ключевым точкам (Path-режим)
var anim3 = new Anim(self, nameof(alpha));
anim3.start([1, 0.5, 1, 0.5, 0], 2, AC_EASE, ANIM_UNITS.SECONDS);
```

## 📖 Документация по API

### 🏗️ Конструктор
```gml
Anim(target, vars)
```
| Параметр | Тип | Описание |
|----------|-----|----------|
| `target` | `instance` **OR** `struct` | Объект или структура, чьи свойства будут анимироваться |
| `vars` | `string` **OR** `array<string>` | Имя переменной или массив имён переменных для анимации. Рекомендуется использовать `nameof()` |

### ⚙️ Методы управления

| Метод | Описание |
|-------|----------|
| `start(endValue, duration, curve, units, perKeyframe)` | Запуск анимации. Если `endValue` — массив, автоматически активируется Path-режим |
| `stop()` | Остановка анимации. Переменные остаются на текущем значении |
| `pause()` | Поставить анимацию на паузу |
| `resume()` | Снять с паузы |
| `togglePause()` | Переключить состояние паузы |
| `getProgress()` | Возвращает текущий прогресс (`0.0` – `1.0`) |
| `isActive()` | `true`, если анимация выполняется |
| `isPaused()` | `true`, если анимация на паузе |

### 🔔 Коллбеки
| Метод | Описание |
|-------|----------|
| `onComplete(callback, deleteAfterCall = false)` | Установить функцию, которая вызовется в конце анимации |
| `onKeyframe(index, callback, deleteAfterCall = false)` | (Path-режим) Коллбек при достижении ключа с индексом `index`. Используйте `ANIM_END` для конца |
| `clearOnComplete()` | Очистить коллбек завершения |
| `clearKeyframeCallback(index)` | Очистить коллбек для конкретного ключа |

### 📐 Перечисления и макросы
```gml
enum ANIM_UNITS { FRAMES, SECONDS }
#macro ANIM_END -1
#macro __ANIM_USE_DELTA false // Измените на true если используете дельту в рассчётах
```