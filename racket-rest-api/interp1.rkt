#lang racket

(require "environment.rkt" "parser.rkt")


(define prog1
  `(bind bacon (bind y 42 (fun x (+ x y)))
         (bind matthias (bind y 68 (fun z (call z y)))
               (call matthias bacon))))


(define prog2
  `(bind !
         (fun x
              (if0 x
                   1
                   (* x (call ! (+ x -1)))))
         (call ! 10)))

(define prog3
  `(bind x 3
         (bind f (fun y (+ x y))
               (bind x 5
                     (call f 4)))))


(module+ test
  (require rackunit)
  (check-equal? (interp prog1) 110)
  (check-equal? (interp prog2) 3628800)
  (check-equal? (interp prog3) 7))


#; {Values = Integer || `(function-value ,Var ,Expr ,Env)}
(define (value? x)
  (or (integer? x)
      (and (cons? x) (equal? (first x) 'function-value))))

; S-expression -> Value
(define (interp lang [env empty])
  (match lang
    [(? number?) lang]
    [(? symbol?) (if (defined? lang env) (lookup lang env) (error "undeclared variable"))]
    [`(+ ,l ,r) (+ (interp l env) (interp r env))]
    [`(* ,l ,r) (* (interp l env) (interp r env))]
    [`(bind ,l ,r ,b) #;(interp b (add l (interp r env) env))
                      (interp b (add-rec l (λ (env) (interp r env)) env))]
    [`(fun ,p ,b) `(function-value ,p ,b ,env)]
    [`(call ,f ,a) (fun-apply (interp f env) (interp a env))]
    [`(if0 ,c ,t ,e)
     (define test-value (interp c env))
     (if (and (number? test-value) (= test-value 0))
         (interp t env)
         (interp e env))]))

; Value Value -> Value 
(define (fun-apply function-representation argument-value)
  (match function-representation
    [`(function-value ,fpara ,fbody ,env)
     (interp fbody (add fpara argument-value env))]))


(displayln (interp (parser (command-line #:args (str) str))))
