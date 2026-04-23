#region Перечисления доступных кривых для возможности переключения

curves = [
	ANIM_CURVE_LINEAR,
	ANIM_CURVE_CIRC,
	ANIM_CURVE_CUBIC,
	ANIM_CURVE_BACK,
	ANIM_CURVE_EASE,
	ANIM_CURVE_ELASTIC,
	ANIM_CURVE_EXPO,
	ANIM_CURVE_BOUNCE,
	ANIM_CURVE_FAST_TO_SLOW,
	ANIM_CURVE_MID_SLOW,
	ANIM_CURVE_QUART,
]
target_curve = 0

#endregion


// Пример анимации в несколько кейфреймов, 
// курвы где значение выходит за пределы между 0 и 1 не применят значения вне диапазона
// для анимируемой переменной
animY = new Anim(self, nameof(y)).onComplete(function () {
	var _nextPos = (self.y > room_height/2 ? room_height/2-200 : room_height/2+200)
	animY.start([100, room_height-100], 1, curves[target_curve])
}).start([100, room_height-100], 1, curves[target_curve])

// Пример анимации в один кейфрейм, можно ставить любую курву
//animX = new Anim(self, nameof(x))
	//.start([room_width/2+200, room_width/2-200], 3, curves[target_curve])
	//.onComplete(function () {
		//animX.start([room_width/2+200, room_width/2-200], 3, curves[target_curve])
	//})



#region Struct AnimTs

ball = {
	x : 200,
	y : room_height/2,
	rad : 50,
	animY : new Anim(self, nameof(y)),
	
	event_draw : function()
	{
		draw_set_color(c_aqua)
		draw_circle(x, y, rad, false)
		draw_set_color(c_white)
	}
}
ball.animY.set_target_inst(ball)
ball.animY.start([100, room_height-100], 1, curves[target_curve])
ball.animY.onComplete(function(){
	ball.animY.start([100, room_height-100], 1, curves[target_curve])
})

#endregion



#region Constructor Anim

///@func Circle
Circle = function() constructor
{
	x = room_width-200
	y = room_height/2
	rad = 50
	
	anim_y = new Anim(self, nameof(y))
	anim_y.start([100, room_height-100], 1, obj_test.curves[obj_test.target_curve])
	anim_y.onComplete(function(){
		anim_y.start([100, room_height-100], 1, obj_test.curves[obj_test.target_curve])
	})
	
	event_draw = function()
	{
		draw_set_color(c_green)
		draw_circle(x, y, rad, false)
		draw_set_color(c_white)
	}
}
circle = new Circle()

#endregion