;;@require $mem "./memory.wast"

;; Graphic routines

(global $display (mut i32) (i32.const -1))

;; Convert rgb values into a single i32
(func $rgb (param $r i32) (param $g i32) (param $b i32) (result i32)
  (local $c i32)
  (set_local $c (i32.const 255))
  (set_local $c (i32.mul (get_local $c) (i32.const 256)))
  (set_local $c (i32.add (get_local $c) (get_local $b)))
  (set_local $c (i32.mul (get_local $c) (i32.const 256)))
  (set_local $c (i32.add (get_local $c) (get_local $g)))
  (set_local $c (i32.mul (get_local $c) (i32.const 256)))
  (set_local $c (i32.add (get_local $c) (get_local $r)))
  (get_local $c)
)

;; Create an image resource
(func $createImg (param $w i32) (param $h i32) (result i32)
  (local $img i32)
  (local $imgOffset i32)
  (set_local $img (call $mem.createPart (i32.add (i32.const 8) (i32.mul (i32.mul (get_local $w) (get_local $h)) (i32.const 4)))))
  (set_local $imgOffset (call $mem.getPartOffset (get_local $img)))
  (i32.store (i32.add (get_local $imgOffset) (i32.const 0)) (get_local $w))
  (i32.store (i32.add (get_local $imgOffset) (i32.const 4)) (get_local $h))
  (get_local $img)
)
;; Get width of image
(func $getImgWidth (param $img i32) (result i32)
  (i32.load (call $mem.getPartOffset (get_local $img)))
)
;; Get height of image
(func $getImgHeight (param $img i32) (result i32)
  (i32.load (i32.add (call $mem.getPartOffset (get_local $img)) (i32.const 4)))
)

;; Get pixel value from image
(func $pget (param $img i32) (param $x i32) (param $y i32) (result i32)
  (local $imgOffset i32)
  (local $imgWidth i32)
  (local $imgHeight i32)
  (local $i i32)
  (set_local $imgOffset (call $mem.getPartOffset (get_local $img)))
  (set_local $imgWidth (i32.load (get_local $imgOffset)))
  (set_local $imgOffset (i32.add (get_local $imgOffset) (i32.const 4)))
  (set_local $imgHeight (i32.load (get_local $imgOffset)))
  (set_local $imgOffset (i32.add (get_local $imgOffset) (i32.const 4)))

  (set_local $i (i32.mul (i32.const 4) (i32.add (get_local $x) (i32.mul (get_local $y) (get_local $imgWidth)))))
  (i32.load (i32.add (get_local $imgOffset) (get_local $i)))
)
;; Set pixel value in image (draw a dot)
(func $pset (param $img i32) (param $x i32) (param $y i32) (param $c i32)
  (local $imgOffset i32)
  (local $imgWidth i32)
  (local $imgHeight i32)
  (local $i i32)
  (set_local $imgOffset (call $mem.getPartOffset (get_local $img)))
  (set_local $imgWidth (i32.load (get_local $imgOffset)))
  (set_local $imgOffset (i32.add (get_local $imgOffset) (i32.const 4)))
  (set_local $imgHeight (i32.load (get_local $imgOffset)))
  (set_local $imgOffset (i32.add (get_local $imgOffset) (i32.const 4)))

  (br_if 0 (i32.ge_u (get_local $x) (get_local $imgWidth)))
  (br_if 0 (i32.ge_u (get_local $y) (get_local $imgHeight)))
  (set_local $i (i32.mul (i32.const 4) (i32.add (get_local $x) (i32.mul (get_local $y) (get_local $imgWidth)))))
  (i32.store (i32.add (get_local $imgOffset) (get_local $i)) (get_local $c))
)

;; Draw rectangle in image
(func $rect (param $img i32) (param $x i32) (param $y i32) (param $w i32) (param $h i32) (param $c i32)
  (local $i i32)
  (local $j i32)
  (local $imgOffset i32)
  (local $imgWidth i32)
  (local $imgHeight i32)
  (set_local $imgOffset (call $mem.getPartOffset (get_local $img)))
  (set_local $imgWidth (i32.load (get_local $imgOffset)))
  (set_local $imgOffset (i32.add (get_local $imgOffset) (i32.const 4)))
  (set_local $imgHeight (i32.load (get_local $imgOffset)))
  (set_local $imgOffset (i32.add (get_local $imgOffset) (i32.const 4)))
  
  (br_if 0 (i32.ge_s (get_local $x) (get_local $imgWidth)))
  (br_if 0 (i32.ge_s (get_local $y) (get_local $imgHeight)))
  (br_if 0 (i32.lt_s (i32.add (get_local $x) (get_local $w)) (i32.const 0)))
  (br_if 0 (i32.lt_s (i32.add (get_local $y) (get_local $h)) (i32.const 0)))
  (if (i32.lt_s (get_local $x) (i32.const 0)) (then
    (set_local $w (i32.add (get_local $w) (get_local $x)))
    (set_local $x (i32.const 0))
  ))
  (if (i32.lt_s (get_local $y) (i32.const 0)) (then
    (set_local $h (i32.add (get_local $h) (get_local $y)))
    (set_local $y (i32.const 0))
  ))
  (if (i32.gt_s (i32.add (get_local $x) (get_local $w)) (get_local $imgWidth)) (then
    (set_local $w (i32.sub (get_local $imgWidth) (get_local $x)))))
  (if (i32.gt_s (i32.add (get_local $y) (get_local $h)) (get_local $imgHeight)) (then
    (set_local $h (i32.sub (get_local $imgHeight) (get_local $y)))))
  (set_local $i (i32.mul (i32.const 4) (i32.add (get_local $x) (i32.mul (get_local $y) (get_local $imgWidth)))))
  (block (loop
    (br_if 1 (i32.eq (get_local $h) (i32.const 0)))
    (set_local $j (get_local $w))
    (block (loop
      (br_if 1 (i32.eq (get_local $j) (i32.const 0)))
      (i32.store (i32.add (get_local $imgOffset) (get_local $i)) (get_local $c))
      (set_local $i (i32.add (get_local $i) (i32.const 4)))
      (set_local $j (i32.sub (get_local $j) (i32.const 1)))
      (br 0)
    ))
    (set_local $i (i32.sub (i32.add (get_local $i) (i32.mul (i32.const 4) (get_local $imgWidth))) (i32.mul (i32.const 4) (get_local $w))))
    (set_local $h (i32.sub (get_local $h) (i32.const 1)))
    (br 0)
  ))
)

;; Copy one image onto another image
(func $copyImg (param $simg i32) (param $sx i32) (param $sy i32) (param $dimg i32) (param $dx i32) (param $dy i32) (param $w i32) (param $h i32)
  (local $x i32)
  (local $y i32)
  (local $c i32)
  (block (set_local $y (i32.const 0)) (loop
    (br_if 1 (i32.ge_u (get_local $y) (get_local $h)))
    (block (set_local $x (i32.const 0)) (loop
      (br_if 1 (i32.ge_u (get_local $x) (get_local $w)))
      (set_local $c (call $pget (get_local $simg)
        (i32.add (get_local $sx) (get_local $x))
        (i32.add (get_local $sy) (get_local $y))
      ))
      (if (i32.gt_u (get_local $c) (i32.const 0x77777777)) (then
        (call $pset (get_local $dimg)
          (i32.add (get_local $dx) (get_local $x))
          (i32.add (get_local $dy) (get_local $y))
          (get_local $c)
        )
      ))
      (set_local $x (i32.add (get_local $x) (i32.const 1)))
      (br 0)
    ))
    (set_local $y (i32.add (get_local $y) (i32.const 1)))
    (br 0)
  ))
)

(global $txtX (mut i32) (i32.const 0))
(global $txtY (mut i32) (i32.const 0))
(global $font (mut i32) (i32.const -1))

;; Move text cursor to location
(func $setTxtCursor (param $x i32) (param $y i32)
  (set_global $txtX (get_local $x))
  (set_global $txtY (get_local $y))
)

;; Print a single character on image
(func $printChar (param $img i32) (param $char i32)
  (call $copyImg (get_global $font) (i32.const 0) (i32.mul (get_local $char) (i32.const 8)) (get_local $img) (get_global $txtX) (get_global $txtY) (i32.const 8) (i32.const 8))
  (set_global $txtX (i32.add (get_global $txtX) (i32.const 8)))
  (if (i32.eq (get_local $char) (i32.const 9)) (then
    (set_global $txtX (i32.sub (get_global $txtX) (i32.const 8)))
    (set_global $txtX (i32.div_u (get_global $txtX) (i32.const 32)))
    (set_global $txtX (i32.mul (get_global $txtX) (i32.const 32)))
    (set_global $txtX (i32.add (get_global $txtX) (i32.const 32)))
  ))
  (if (i32.eq (get_local $char) (i32.const 10)) (then
    (set_global $txtX (i32.const 0))
    (set_global $txtY (i32.add (get_global $txtY) (i32.const 8)))
  ))
  (if (i32.ge_u (get_global $txtX) (call $getImgWidth (get_local $img))) (then
    (set_global $txtX (i32.const 0))
    (set_global $txtY (i32.add (get_global $txtY) (i32.const 8)))
  ))
  (if (i32.ge_u (get_global $txtY) (call $getImgHeight (get_local $img))) (then
    (call $copyImg (get_local $img) (i32.const 0) (i32.const 8) (get_local $img) (i32.const 0) (i32.const 0) (call $getImgWidth (get_local $img)) (i32.sub (call $getImgHeight (get_local $img)) (i32.const 8)))
    (call $rect (get_local $img) (i32.const 0) (i32.sub (call $getImgHeight (get_local $img)) (i32.const 8)) (call $getImgWidth (get_local $img)) (i32.const 8) (call $pget (get_local $img) (i32.sub (call $getImgWidth (get_local $img)) (i32.const 1)) (i32.sub (call $getImgHeight (get_local $img)) (i32.const 1))))
    (set_global $txtY (i32.sub (get_global $txtY) (i32.const 8)))
  ))
)

;; Print a string to image
(func $printStr (param $img i32) (param $str i32)
  (local $i i32)
  (local $len i32)
  (set_local $i (call $mem.getPartOffset (get_local $str)))
  (set_local $len (call $mem.getPartLength (get_local $str)))
  (if (i32.gt_u (get_local $len) (i32.const 0)) (then
    (loop
      (call $printChar (get_local $img) (i32.load8_u (get_local $i)))
      (set_local $i (i32.add (get_local $i) (i32.const 1)))
      (set_local $len (i32.sub (get_local $len) (i32.const 1)))
      (br_if 0 (i32.gt_u (get_local $len) (i32.const 0)))
    )
  ))
)

;; Print user input on image
(func $printInput (param $img i32) (param $str i32) (param $pos i32) (param $sel i32) (param $c i32)
  (local $i i32)
  (local $len i32)
  (set_local $i (call $mem.getPartOffset (get_local $str)))
  (set_local $len (call $mem.getPartLength (get_local $str)))
  (if (i32.gt_u (get_local $len) (i32.const 0)) (then
    (loop
      (if (i32.eq (get_local $pos) (i32.const 0)) (then
        (if (i32.gt_u (get_local $sel) (i32.const 0)) (then
          (call $rect (get_local $img) (get_global $txtX) (get_global $txtY) (i32.const 8) (i32.const 8) (get_local $c))
          (set_local $sel (i32.sub (get_local $sel) (i32.const 1)))
        )(else
          (call $rect (get_local $img) (get_global $txtX) (get_global $txtY) (i32.const 1) (i32.const 8) (get_local $c))
          (set_local $pos (i32.sub (get_local $pos) (i32.const 1)))
        ))
      )(else
        (set_local $pos (i32.sub (get_local $pos) (i32.const 1)))
      ))
      (call $printChar (get_local $img) (i32.load8_u (get_local $i)))
      (set_local $i (i32.add (get_local $i) (i32.const 1)))
      (set_local $len (i32.sub (get_local $len) (i32.const 1)))
      (br_if 0 (i32.gt_u (get_local $len) (i32.const 0)))
    )
    (if (i32.eq (get_local $pos) (i32.const 0)) (then
      (if (i32.gt_u (get_local $sel) (i32.const 0)) (then
        (call $rect (get_local $img) (get_global $txtX) (get_global $txtY) (i32.const 8) (i32.const 8) (get_local $c))
        (set_local $sel (i32.sub (get_local $sel) (i32.const 1)))
      )(else
        (call $rect (get_local $img) (get_global $txtX) (get_global $txtY) (i32.const 1) (i32.const 8) (get_local $c))
        (set_local $pos (i32.sub (get_local $pos) (i32.const 1)))
      ))
    )(else
      (set_local $pos (i32.sub (get_local $pos) (i32.const 1)))
    ))
  ))
)
