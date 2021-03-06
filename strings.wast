(import "env" "pushFromMemory" (func $fi.pushFromMemory (param i32) (param i32) ))
(import "env" "popToMemory" (func $fi.popToMemory (param i32) ))
(import "env" "getBufferSize" (func $fi.getBufferSize (result i32)))
(import "env" "print" (func $fi.print ))
;;@require $mem "./memory.wast"

;; String manipulation

;; print a string in text mode
(func $printStr (param $str i32)
  (call $fi.print (call $fi.pushFromMemory (call $mem.getPartOffset (get_local $str)) (call $mem.getPartLength (get_local $str))))
)

;; Create a string from null-terminated string in memory
(func $createString (param $srcOffset i32) (result i32)
  (local $str i32)
  (local $len i32)
  (set_local $len (i32.const 0))
  (block(loop
    (br_if 1 (i32.eq (i32.load8_u (i32.add (get_local $srcOffset) (get_local $len))) (i32.const 0)))
    (set_local $len (i32.add (get_local $len) (i32.const 1)))
    (br 0)
  ))
  (set_local $str (call $mem.createPart (get_local $len)))
  (call $mem.copyMem (get_local $srcOffset) (call $mem.getPartOffset (get_local $str)) (get_local $len))
  (get_local $str)
)

;; Get byte at position in string
(func $byteAt (param $str i32) (param $pos i32) (result i32)
  (i32.load8_u (i32.add (call $mem.getPartOffset (get_local $str)) (get_local $pos)))
)

;; Create string from part of another string
(func $substr (param $str i32) (param $pos i32) (param $len i32) (result i32)
  (local $strc i32)
  (if (i32.gt_u (get_local $pos) (call $mem.getPartLength (get_local $str))) (then
    (set_local $pos (call $mem.getPartLength (get_local $str)))
  ))
  (if (i32.gt_u (get_local $len) (i32.sub (call $mem.getPartLength (get_local $str)) (get_local $pos))) (then
    (set_local $len (i32.sub (call $mem.getPartLength (get_local $str)) (get_local $pos)) )
  ))
  (set_local $strc (call $mem.createPart (get_local $len)))
  (call $mem.copyMem (i32.add (call $mem.getPartOffset (get_local $str)) (get_local $pos)) (call $mem.getPartOffset (get_local $strc)) (get_local $len))
  (get_local $strc)
)

;; Create string by concatenating two strings
(func $concat (param $stra i32) (param $strb i32) (result i32)
  (local $strc i32)
  (set_local $strc (call $mem.createPart (i32.add (call $mem.getPartLength (get_local $stra)) (call $mem.getPartLength (get_local $strb)))))
  (call $mem.copyMem (call $mem.getPartOffset (get_local $stra)) (call $mem.getPartOffset (get_local $strc)) (call $mem.getPartLength (get_local $stra)))
  (call $mem.copyMem (call $mem.getPartOffset (get_local $strb)) (i32.add (call $mem.getPartOffset (get_local $strc)) (call $mem.getPartLength (get_local $stra))) (call $mem.getPartLength (get_local $strb)))
  (get_local $strc)
)

;; Append bytes to string
(func $appendBytes (param $str i32) (param $bytes i64)
  (local $l i32)
  (set_local $l (call $mem.getPartLength (get_local $str)))
  (call $mem.resizePart (get_local $str) (i32.add (get_local $l) (i32.const 9)))
  (set_local $l (i32.add (get_local $l) (i32.const 1)))
  (i64.store (i32.add (call $mem.getPartOffset (get_local $str)) (get_local $l)) (i64.const 0))
  (set_local $l (i32.sub (get_local $l) (i32.const 1)))
  (i64.store (i32.add (call $mem.getPartOffset (get_local $str)) (get_local $l)) (get_local $bytes))
  (set_local $l (i32.add (get_local $l) (i32.const 1)))
  (block(loop
    (br_if 1 (i32.eq (call $byteAt (get_local $str) (get_local $l)) (i32.const 0)))
    (set_local $l (i32.add (get_local $l) (i32.const 1)))
    (br 0)
  ))
  (call $mem.resizePart (get_local $str) (get_local $l))
)

;; Force string into 7-bit ascii
(func $usascii (param $str i32)
  (local $i i32)
  (local $l i32)
  (set_local $i (call $mem.getPartOffset (get_local $str)))
  (set_local $l (call $mem.getPartLength (get_local $str)))
  (block (loop
    (br_if 1 (i32.eq (get_local $l) (i32.const 0)))
    (if (i32.gt_u (i32.load8_u (get_local $i)) (i32.const 127)) (then
      (i32.store8 (get_local $i) (i32.const 63))
    ))
    (set_local $i (i32.add (get_local $i) (i32.const 1)))
    (set_local $l (i32.sub (get_local $l) (i32.const 1)))
    (br 0)
  ))
)

;; Create string from line in string
(func $getLine (param $str i32) (param $linenum i32) (result i32)
  (local $line i32)
  (local $col i32)
  (local $p i32)
  (local $strc i32)
  (block(loop
    (br_if 1 (get_local $strc))
    (set_local $col (i32.add (get_local $col) (i32.const 1)))
    (if (i32.eq (call $byteAt (get_local $str) (get_local $p)) (i32.const 10)) (then
      (if (i32.eq (get_local $line) (get_local $linenum)) (then
        (set_local $p (i32.sub (get_local $p) (i32.sub (get_local $col) (i32.const 1))))
        (set_local $strc (call $substr (get_local $str) (get_local $p) (get_local $col)))
        (set_local $p (i32.add (get_local $p) (i32.sub (get_local $col) (i32.const 1))))
      ))
      (set_local $line (i32.add (get_local $line) (i32.const 1)))
      (set_local $col (i32.const 0))
    ))
    (set_local $p (i32.add (get_local $p) (i32.const 1)))
    (br 0)
  ))
  (get_local $strc)
)

;; Count lines in string
(func $countLines (param $str i32) (result i32)
  (local $line i32)
  (local $p i32)
  (local $l i32)
  (set_local $line (i32.const 1))
  (set_local $l (call $mem.getPartLength (get_local $str)))
  (block(loop
    (br_if 1 (i32.ge_u (get_local $p) (get_local $l)))
    (if (i32.eq (call $byteAt (get_local $str) (get_local $p)) (i32.const 10)) (then
      (set_local $line (i32.add (get_local $line) (i32.const 1)))
    ))
    (set_local $p (i32.add (get_local $p) (i32.const 1)))
    (br 0)
  ))
  (get_local $line)
)

;; Get linenumber at position in string
(func $lineAt (param $str i32) (param $pos i32) (result i32)
  (local $line i32)
  (local $p i32)
  (block(loop
    (br_if 1 (i32.eq (get_local $p) (get_local $pos)))
    (if (i32.eq (call $byteAt (get_local $str) (get_local $p)) (i32.const 10)) (then
      (set_local $line (i32.add (get_local $line) (i32.const 1)))
    ))
    (set_local $p (i32.add (get_local $p) (i32.const 1)))
    (br 0)
  ))
  (get_local $line)
)

;; Get column at position in string
(func $columnAt (param $str i32) (param $pos i32) (result i32)
  (local $col i32)
  (local $p i32)
  (block(loop
    (br_if 1 (i32.eq (get_local $p) (get_local $pos)))
    (set_local $col (i32.add (get_local $col) (i32.const 1)))
    (if (i32.eq (call $byteAt (get_local $str) (get_local $p)) (i32.const 10)) (then
      (set_local $col (i32.const 0))
    ))
    (set_local $p   (i32.add (get_local $p)   (i32.const 1)))
    (br 0)
  ))
  (get_local $col)
)

;; Create decimal string representation of unsigned integer
(func $uintToStr (param $int i32) (result i32)
  (local $order i32)
  (local $digit i32)
  (local $str i32)
  (set_local $order (i32.const 1000000000))
  (set_local $str (call $mem.createPart (i32.const 0)))
  (block(loop
    (br_if 1 (i32.eq (get_local $order) (i32.const 0)))
    (set_local $digit (i32.div_u (get_local $int) (get_local $order)))
    (if (i32.or (get_local $digit) (call $mem.getPartLength (get_local $str))) (then
      (call $appendBytes (get_local $str) (i64.extend_u/i32 (i32.add (i32.const 0x30) (get_local $digit))))
    ))
    (set_local $int (i32.rem_u (get_local $int) (get_local $order)))
    (set_local $order (i32.div_u (get_local $order) (i32.const 10)))
    (br 0)
  ))
  (if (i32.eqz (call $mem.getPartLength (get_local $str)))(then
    (call $appendBytes (get_local $str) (i64.const 0x30) )
  ))
  (get_local $str)
)

;; Check wether two strings are identical
(func $equal (param $stra i32) (param $strb i32) (result i32)
  (local $p i32)
  (local $l i32)
  (if (i32.ne (call $mem.getPartLength (get_local $stra)) (call $mem.getPartLength (get_local $strb))) (then
    (return (i32.const 0))
  ))
  (set_local $l (call $mem.getPartLength (get_local $stra)))
  (block(loop
    (br_if 1 (i32.eq (get_local $p) (get_local $l)))
    (if (i32.ne (call $byteAt (get_local $stra) (get_local $p)) (call $byteAt (get_local $strb) (get_local $p))) (then
      (return (i32.const 0))
    ))
    (set_local $p (i32.add (get_local $p) (i32.const 1)))
    (br 0)
  ))
  (i32.const 1)
)

;; Get position of first occurrence of substring. -1 if not found.
(func $indexOf (param $haystack i32) (param $needle i32) (param $pos i32) (result i32)
  (local $sub i32)
  (if (i32.lt_u (call $mem.getPartLength (get_local $haystack)) (call $mem.getPartLength (get_local $needle))) (then
    (return (i32.const -1))
  ))
  (set_local $sub (call $mem.createPart (call $mem.getPartLength (get_local $needle))))
  (block(loop
    (br_if 1 (i32.ge_u (get_local $pos) (i32.sub (call $mem.getPartLength (get_local $haystack)) (call $mem.getPartLength (get_local $needle)))))
    (call $mem.copyMem (i32.add (call $mem.getPartOffset (get_local $haystack)) (get_local $pos)) (call $mem.getPartOffset (get_local $sub)) (call $mem.getPartLength (get_local $sub)))
    (if (call $equal (get_local $sub) (get_local $needle)) (then
      (return (get_local $pos))
    ))
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
    (br 0)
  ))
  (i32.const -1)
)

;; Get position of last occurrence of substring. -1 if not found.
(func $lastIndexOf (param $haystack i32) (param $needle i32) (param $pos i32) (result i32)
  (local $sub i32)
  (if (i32.lt_u (call $mem.getPartLength (get_local $haystack)) (call $mem.getPartLength (get_local $needle))) (then
    (return (i32.const -1))
  ))
  (set_local $sub (call $mem.createPart (call $mem.getPartLength (get_local $needle))))
  (block(loop
    (br_if 1 (i32.eq (get_local $pos) (i32.const 0)))
    (call $mem.copyMem (i32.add (call $mem.getPartOffset (get_local $haystack)) (get_local $pos)) (call $mem.getPartOffset (get_local $sub)) (call $mem.getPartLength (get_local $sub)))
    (if (call $equal (get_local $sub) (get_local $needle)) (then
      (return (get_local $pos))
    ))
    (set_local $pos (i32.sub (get_local $pos) (i32.const 1)))
    (br 0)
  ))
  (i32.const -1)
)

;; Trim whitespace from beginning and end of string
(func $trim (param $str i32)
  (local $p i32)
  (local $l i32)
  (set_local $p (call $mem.getPartOffset (get_local $str)))
  (set_local $l (call $mem.getPartLength (get_local $str)))
  (block(loop
    (br_if 1 (i32.or (i32.eqz (get_local $l)) (i32.gt_u (i32.load8_u (get_local $p)) (i32.const 32))))
    (set_local $p (i32.add (get_local $p) (i32.const 1)))
    (set_local $l (i32.sub (get_local $l) (i32.const 1)))
    (br 0)
  ))
  (call $mem.copyMem (get_local $p) (call $mem.getPartOffset (get_local $str)) (get_local $l))
  (block(loop
    (br_if 1 (i32.or (i32.eqz (get_local $l)) (i32.gt_u (call $byteAt (get_local $str) (i32.sub (get_local $l) (i32.const 1))) (i32.const 32))))
    (set_local $l (i32.sub (get_local $l) (i32.const 1)))
    (br 0)
  ))
  (call $mem.resizePart (get_local $str) (get_local $l))
)

;; Push string to buffer stack
(func $pushString (param $str i32)
  (call $fi.pushFromMemory (call $mem.getPartOffset (get_local $str)) (call $mem.getPartLength (get_local $str)))
)

;; Pop string from buffer stack
(func $popString (result i32)
  (local $str i32)
  (set_local $str (call $mem.createPart (call $fi.getBufferSize)))
  (call $fi.popToMemory (call $mem.getPartOffset (get_local $str)))
  (get_local $str)
)
