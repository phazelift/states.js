# states.js - A range iteration tool, written in Coffeescript.
#
#	States is a ranged states iteration tool:
#
# 	- very robust; cannot exeed range bounds
# 	- dynamically adjust step-size, range, position etc..
# 	- set callbacks on any index
# 	- build-in interval for delayed/auto iteration over the range
# 	- 4 iteration patterns: 'limit', 'rotate', 'yoyo', 'random'
#
#
# Copyright (c) 2015 Dennis Raymondo van der Sluis
#
# This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>


"use strict"


# get types.js
if not _= window?.Types
	_= require 'types.js'

return if not _




class States

	# private

		limit= ( value, min, max ) ->
			return max if value > max
			return min if value < min
			return value

	# static

	# dynamic

		constructor: ( init ) ->

			init			= _.forceObject init
			@min			= _.forceNumber init['min'], 1
			@current	= _.forceNumber init['current'], @min
			@stepSize	= _.forceNumber init['stepSize'], 1

			# @setMax calls @updateRange to adust @min, @current, @range and @stepSize to the new 'max'
			# only call @setMax after @min, @current and @stepSize are set
			@setMax init['max'] or @min

			@up				= _.forceBoolean init['up'], true
			@pattern	= _.forceString init['pattern'], 'limit'

			# default the interval to 1 sec
			@delay		= _.forceNumber init['delay'], 1000
			@events		= {}
			@defaultEvent= -> ''



		setStep: ( newStep= @stepSize ) ->	@stepSize= limit newStep, 1, @range



		updateRange: ->
			@current	= limit @current, @min, @max
			@range		= (@max+ 1)- @min
			@setStep()
			return @range



		setMin: ( newMin ) ->
			newMin= _.forceNumber newMin
			if not newMin.void
				@min= limit newMin, newMin, @max
				@updateRange()
			return @min



		setMax: ( newMax ) ->
			newMax= _.forceNumber( newMax )
			if not newMax.void
				@max= newMax
				@min= limit @min, @min, @max
				@updateRange()
			return @max



		setCurrent: ( newCurrent ) ->
			newCurrent= _.forceNumber newCurrent
			if newCurrent.void
				return @current
			return @current= limit newCurrent, @min, @max



		limit: ( step ) -> limit @current+ step, @min, @max



		rotate: ( step ) ->
			current= @current+ step
			if current < @min
				return @max- ( @min- (current+ 1) )
			if current > @max
				return @min+ ( (current- 1)- @max )
			return current



		yoyo: ->
			if @range is @stepSize
				if @up
					return @max
				else
				return @min

			next= @current+ @stepSize
			if @up and (next > @max)
				@up= false
				return @max- (next- @max)

			prev= @current- @stepSize
			if not @up and (prev < @min)
				@up= true
				return @min- (prev- @min)

			if @up
				return next

			return prev



		# TODO: add spread from @stepSize, so @stepSize becomes the minimum distance between two values
		random: -> @current= ( (Math.random( @range )* @range) | 0 )+ @min



		peek: ( amount ) ->
			switch amount
				when undefined 	then amount= @stepSize
				when false 			then amount= -@stepSize
				else do =>
					amount= _.forceNumber amount, 0
					if (Math.abs amount) >= @range
						amount= 0
			return @[ @pattern ] amount



		eachStep: ( stepSize= @stepSize, callback ) ->

			# allow for passing only the callback
			if _.isFunction stepSize
				callback= stepSize
				stepSize= @stepSize

			# allow for backwards traversal on passing negative numbers
			if stepSize < 0
				stepSize= Math.abs stepSize
				[min, max]= [@max, @min]
			else
				[min, max]= [@min, @max]

			# fill results with index or callback return
			results= []
			for index in [min..max]
				if index % stepSize is 0
					if not callback
						results.push index
					else
						results.push callback index

			return results



		each: ( callback ) -> @eachStep 1, callback



		addEvent: ( index, callback ) -> @events[ index ]= callback



		removeEvent: ( index ) -> delete @events[ index ]


		call: ( index= @current, args... ) ->
			args.unshift index
			return _.forceFunction( @events[index], => @defaultEvent(args) ) args...


		next: -> @current= @[ @pattern ] @stepSize

		nextCall: ( args... ) -> @call @next(), args



		prev: -> @current= @[ @pattern ] -@stepSize

		prevCall: ( args... ) -> @call @prev(), args



		run: ( index ) ->

			down= index < 0
			if not @interval
				index= @setCurrent index
				@interval= setInterval =>
					if down
						@call @prev()
					else
						@call @next()
				, @delay


		stop: -> @interval|= clearInterval @interval

# end of States



if define? and ( 'function' is typeof define ) and define.amd
	define 'states', [], -> States

else if typeof module isnt 'undefined'
	module.exports= States

else if typeof window isnt 'undefined'
	window.States= States