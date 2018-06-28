;;@require $mem "./memory.wast"
;;@require $str "./strings.wast"

;; Get char size from the first byte
(func $charSize (param $byte i32) (result i32)
  (local $pos i32)
  (if (i32.ge_u (get_local $byte) (i32.const 0x01))(then
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xc0))(then
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xe0))(then
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xf0))(then
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xf8))(then
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xfc))(then
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xfe))(then
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xff))(then
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
  ))
  (get_local $pos)
)

;; Get offset of next char
(func $nextChar (param $pos i32) (result i32)
  (local $byte i32)
  (set_local $byte (i32.load8_u (get_local $pos)))
  (i32.add (get_local $pos) (call $charSize (get_local $byte)))
)

;; Get character length of string
(func $getLength (param $str i32) (result i32)
  (local $pos i32)
  (local $len i32)
  (local $byte i32)
  (local $chars i32)
  (set_local $pos (call $mem.getPartOffset (get_local $str)))
  (set_local $len (call $mem.getPartLength (get_local $str)))
  (block(loop
    (br_if 1 (i32.le_s (get_local $len) (i32.const 0)))
    (set_local $byte (i32.load8_u (get_local $pos)))
    (set_local $len (i32.sub (get_local $len) (call $charSize (get_local $byte))))
    (set_local $pos (call $nextChar (get_local $pos)))
    (br 0)
  ))
  (get_local $chars)
)

;; Get char at position in string
(func $charAt (param $str i32) (param $pos i32) (result i32)
  (local $offset i32)
  (local $len i32)
  (local $byte i32)
  (local $mask i32)
  (local $bit i32)
  (local $char i32)
  (set_local $offset (call $mem.getPartOffset (get_local $str)))
  (block(loop
    (br_if 1 (i32.eqz (get_local $pos)))
    (set_local $offset (call $nextChar (get_local $offset)))
    (set_local $pos (i32.sub (get_local $pos) (i32.const 1)))
    (br 0)
  ))
  (set_local $byte (i32.load8_u (get_local $offset)))
  (set_local $len (call $charSize (get_local $byte)))
  (block(loop
    (br_if 1 (i32.eqz (get_local $len)))
    (set_local $bit (i32.const 128))
    (set_local $mask (i32.const 0))
    (block(loop
      (br_if 1 (i32.eqz (i32.and (get_local $bit) (get_local $byte))))
      (set_local $mask (i32.add (get_local $mask) (get_local $bit)))
      (set_local $bit (i32.div_u (get_local $bit) (i32.const 2)))
      (br 0)
    ))
    (set_local $char (i32.mul (get_local $char) (i32.const 64)))
    (set_local $char (i32.add (get_local $char) (i32.xor (get_local $byte) (get_local $mask))))
    (set_local $offset (i32.add (get_local $offset) (i32.const 1)))
    (set_local $byte (i32.load8_u (get_local $offset)))
    (set_local $len (i32.sub (get_local $len) (i32.const 1)))
    (br 0)
  ))
  (get_local $char)
)

;; convert character position to bytes
(func $charsToBytes (param $str i32) (param $chars i32) (result i32)
  (local $bytes i32)
  (set_local $bytes (call $mem.getPartOffset (get_local $str)))
  (block(loop
    (br_if 1 (i32.eqz (get_local $chars)))
    (set_local $bytes (call $nextChar (get_local $bytes)))
    (set_local $chars (i32.sub (get_local $chars) (i32.const 1)))
    (br 0)
  ))
  (i32.sub (get_local $bytes) (call $mem.getPartOffset (get_local $str)))
)

;; Create string from part of another string
(func $substr (param $str i32) (param $pos i32) (param $len i32) (result i32)
  (set_local $len (call $charsToBytes (get_local $str) (i32.add (get_local $pos) (get_local $len))))
  (set_local $pos (call $charsToBytes (get_local $str) (get_local $pos)))
  (set_local $len (i32.sub (get_local $len) (get_local $pos)))
  (call $str.substr (get_local $str) (get_local $pos) (get_local $len))
)

;; Get linenumber at position in string
(func $lineAt (param $str i32) (param $pos i32) (result i32)
  (set_local $pos (call $charsToBytes (get_local $str) (get_local $pos)))
  (call $str.lineAt (get_local $str) (get_local $pos))
)

;; Get column at position in string
(func $columnAt (param $str i32) (param $pos i32) (result i32)
  (local $col i32)
  (call $mem.enterPart (call $mem.createPart (i32.const 0)))
  (set_local $pos (call $charsToBytes (get_local $str) (get_local $pos)))
  (set_local $col (call $str.columnAt (get_local $str) (get_local $pos)))
  (set_local $pos (i32.sub (get_local $pos) (get_local $col)))
  (call $getLength (call $str.substr (get_local $str) (get_local $pos) (get_local $col)))
  (call $mem.deleteParent)
)

;; Get position of first occurrence of substring. -1 if not found.
(func $indexOf (param $haystack i32) (param $needle i32) (param $pos i32) (result i32)
  (local $col i32)
  (call $mem.enterPart (call $mem.createPart (i32.const 0)))
  (set_local $pos (call $charsToBytes (get_local $haystack) (get_local $pos)))
  (set_local $col (call $str.indexOf (get_local $haystack) (get_local $needle) (get_local $pos)))
  (if (i32.ge_s (get_local $col) (i32.const 0))(then
    (set_local $col (call $getLength (call $str.substr (get_local $haystack) (i32.const 0) (get_local $col))))
  ))
  (call $mem.deleteParent)
  (get_local $col)
)

;; Get position of last occurrence of substring. -1 if not found.
(func $lastIndexOf (param $haystack i32) (param $needle i32) (param $pos i32) (result i32)
  (local $col i32)
  (call $mem.enterPart (call $mem.createPart (i32.const 0)))
  (set_local $pos (call $charsToBytes (get_local $haystack) (get_local $pos)))
  (set_local $col (call $str.lastIndexOf (get_local $haystack) (get_local $needle) (get_local $pos)))
  (if (i32.ge_s (get_local $col) (i32.const 0))(then
    (set_local $col (call $getLength (call $str.substr (get_local $haystack) (i32.const 0) (get_local $col))))
  ))
  (call $mem.deleteParent)
  (get_local $col)
)
