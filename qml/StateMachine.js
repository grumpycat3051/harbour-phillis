/* The MIT License (MIT)
 *
 * Copyright (c) 2020 grumpycat <grumpycat3051@protonmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

function StateMachine(name) {
    var defaultLogger = function() {}
    this.name = name
    this.states = []
    this.active = []
    this.transitions = []
    this.initialState = null
    this.finalState = null
    this.isInitialized = false
    this.logger = defaultLogger

    StateMachine.prototype.setLogger = function (logger) {
        this.logger = logger ? logger : defaultLogger
    }

    StateMachine.prototype.addState = function(name, onEnter, onExit) {
        var s = {
            name: name,
            enter: onEnter ? onEnter : function () {},
            exit: onExit ? onExit : function () {},
        }

        this.states.push(s)
        return s
    }

    StateMachine.prototype.addState = function(name, onEnter, onExit) {
        var s = {
            name: name,
            enter: onEnter ? onEnter : function () {},
            exit: onExit ? onExit : function () {},
            out: []
        }

        this.states.push(s)
        return s
    }

    StateMachine.prototype.addTransition = function(from, to, condititon, onExec) {
        if (!from) {
            throw "from"
        }

        if (!to) {
            throw "to"
        }

        this.transitions.push({
                           from: from,
                           to: to,
                           guard: condititon ? condititon : function() { return true; },
                           exec: onExec ? onExec : function() {}
                       })
    }

    StateMachine.prototype.start = function() {
        if (!this.initialState) {
            console.warn("state machine '" + this.name + "' has no initial state")
            return
        }

        this.active = [this.initialState]

        if (!this.isInitialized) {
            for (var i = 0; i < this.transitions.length; ++i) {
                var t = this.transitions[i]
                t.from.out.push(t)
            }
        }
    }

    StateMachine.prototype.tick = function() {
        for (var change = true; change; ) {
            change = false

            var newActive = []
            for (var i = 0; i < this.active.length; ++i) {
                var s = this.active[i]
                var added = false
                for (var j = 0; j < s.out.length; ++j) {
                    var t = s.out[j]
                    if (t.guard()) {
                        this.logger(this.name + ": " + t.from.name + " -> " + t.to.name)
                        t.exec()
                        newActive.push(t.to)
                        added = true
                        change = true
                    }
                }

                if (!added) {
                    newActive.push(s)
                }
            }
            this.active = newActive
        }
    }
}

function create(name) {
    return new StateMachine(name)
}
