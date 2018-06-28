(import "env" "pushFromMemory" (func $pushFromMemory (param $offset i32) (param $length i32)))
(import "env" "popToMemory" (func $popToMemory (param $offset i32)))
(import "env" "getInputText" (func $getInputText (result i32)))
(import "env" "getInputPosition" (func $getInputPosition (result i32)))
(import "env" "getInputSelected" (func $getInputSelected (result i32)))
(import "env" "getInputKey" (func $getInputKey (result i32)))
(import "env" "setInputText" (func $setInputText ))
(import "env" "print" (func $print ))

;;@require $mem "./memory.wast"
;;@require $str "./strings.wast"
;;@require $utf8 "./utf8.wast"

(global $restore (mut i32) (i32.const 0))
(global $save (mut i32) (i32.const 0))
(global $clear (mut i32) (i32.const 0))
(global $nl (mut i32) (i32.const 0))
(global $selstart (mut i32) (i32.const 0))
(global $selend (mut i32) (i32.const 0))
(global $input (mut i32) (i32.const 0))
(global $inputLen (mut i32) (i32.const 0))

(func $step (result i32)
  (local $key i32)
  (local $result i32)
  (local $parentPart i32)
  (set_local $parentPart (get_global $mem.parentPart))
  (set_global $mem.parentPart (i32.const 0))
  (if (i32.eqz (get_global $restore))(then
    (set_global $restore (call $mem.createPart (i32.const 0)))
    (call $str.appendBytes (get_global $restore) (i64.const 0x755b1b))
  ))
  (if (i32.eqz (get_global $save))(then
    (set_global $save (call $mem.createPart (i32.const 0)))
    (call $str.appendBytes (get_global $save) (i64.const 0x735b1b))
  ))
  (if (i32.eqz (get_global $clear))(then
    (set_global $clear (call $mem.createPart (i32.const 0)))
    (call $str.appendBytes (get_global $clear) (i64.const 0x4a5b1b))
  ))
  (if (i32.eqz (get_global $nl))(then
    (set_global $nl (call $mem.createPart (i32.const 0)))
    (call $str.appendBytes (get_global $nl) (i64.const 0x0a))
  ))
  (if (i32.eqz (get_global $selstart))(then
    (set_global $selstart (call $mem.createPart (i32.const 0)))
    (call $str.appendBytes (get_global $selstart) (i64.const 0x6d30333b37345b1b))
  ))
  (if (i32.eqz (get_global $selend))(then
    (set_global $selend (call $mem.createPart (i32.const 0)))
    (call $str.appendBytes (get_global $selend) (i64.const 0x6d305b1b))
  ))
  (if (i32.eqz (get_global $input))(then
    (set_global $input (call $mem.createPart (i32.const 0)))
  ))
  (set_global $mem.parentPart (get_local $parentPart))
  (call $mem.enterPart (call $mem.createPart (i32.const 0)))
  (call $mem.resizePart (get_global $input) (call $getInputText))
  (call $popToMemory (call $mem.getPartOffset (get_global $input)))
  (set_local $key (call $getInputKey))
  (if (get_local $key)(then
    (if (i32.eq (get_local $key) (i32.const 13))(then
      (call $setInputText (call $pushFromMemory (i32.const 0) (i32.const 0)))
      (call $str.trim (get_global $input))
      (call $str.printStr (get_global $restore))
      (call $str.printStr (get_global $input))
      (call $str.printStr (get_global $clear))
      (call $str.printStr (get_global $nl))
      (set_local $result (get_global $input))
    )(else
      (call $str.printStr (get_global $restore))
      (call $str.printStr (get_global $save))
      (call $str.printStr (call $utf8.substr (get_global $input) (i32.const 0) (call $getInputPosition)))
      (call $str.printStr (get_global $save))
      (call $str.printStr (get_global $selstart))
      (call $str.printStr (call $utf8.substr (get_global $input) (call $getInputPosition) (call $getInputSelected)))
      (call $str.printStr (get_global $selend))
      (call $str.printStr (call $utf8.substr (get_global $input) (i32.add (call $getInputPosition) (call $getInputSelected)) (i32.sub (call $mem.getPartLength (get_global $input)) (i32.add (call $getInputPosition) (call $getInputSelected)))))
      (if (i32.lt_u (call $mem.getPartLength (get_global $input)) (get_global $inputLen))(then
        (call $str.printStr (get_global $clear))
      ))
      (call $str.printStr (get_global $restore))
      (set_global $inputLen (call $mem.getPartLength (get_global $input)))
      (set_local $result (i32.const 0))
    ))
  ))
  (get_local $result)
  (call $mem.deleteParent)
)

(func $countArgs (result i32)
  (local $num i32)
  (local $pos i32)
  (local $len i32)
  (local $end i32)
  (local $chr i32)
  (set_local $len (call $mem.getPartLength (get_global $input)))
  (block(loop
    (br_if 1 (i32.eqz (get_local $len)))
    (set_local $len (i32.sub (get_local $len) (i32.const 1)))
    (set_local $chr (call $str.byteAt (get_global $input) (get_local $pos)))
    (if (i32.and (i32.eqz (get_local $end)) (i32.gt_u (get_local $chr) (i32.const 0x20)))(then
      (if (i32.eq (get_local $chr) (i32.const 0x22))(then
        (set_local $end (get_local $chr))
        (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
        (if (get_local $len) (set_local $len (i32.sub (get_local $len) (i32.const 1))))
        (set_local $chr (call $str.byteAt (get_global $input) (get_local $pos)))
      )(else
        (set_local $end (i32.const 0x20))
      ))
      (set_local $num (i32.add (get_local $num) (i32.const 1)))
    ))
    (if (i32.eq (get_local $chr) (get_local $end))(then
      (set_local $end (i32.const 0))
    ))
    (if (i32.eq (get_local $chr) (i32.const 0x5c))(then
      (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
      (if (get_local $len) (set_local $len (i32.sub (get_local $len) (i32.const 1))))
    ))
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
    (br 0)
  ))
  (get_local $num)
)

(func $getArg (param $num i32) (result i32)
  (local $arg i32)
  (local $pos i32)
  (local $len i32)
  (local $end i32)
  (local $chr i32)
  (set_local $arg (call $mem.createPart (i32.const 0)))
  (set_local $len (call $mem.getPartLength (get_global $input)))
  (block(loop
    (br_if 1 (i32.eqz (get_local $len)))
    (set_local $len (i32.sub (get_local $len) (i32.const 1)))
    (set_local $chr (call $str.byteAt (get_global $input) (get_local $pos)))
    (if (i32.and (i32.eqz (get_local $end)) (i32.gt_u (get_local $chr) (i32.const 0x20)))(then
      (if (i32.eq (get_local $chr) (i32.const 0x22))(then
        (set_local $end (get_local $chr))
        (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
        (if (get_local $len) (set_local $len (i32.sub (get_local $len) (i32.const 1))))
        (set_local $chr (call $str.byteAt (get_global $input) (get_local $pos)))
      )(else
        (set_local $end (i32.const 0x20))
      ))
    ))
    (if (i32.eq (get_local $chr) (get_local $end))(then
      (set_local $end (i32.const 0))
      (set_local $num (i32.sub (get_local $num) (i32.const 1)))
    ))
    (if (i32.eq (get_local $chr) (i32.const 0x5c))(then
      (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
      (if (get_local $len) (set_local $len (i32.sub (get_local $len) (i32.const 1))))
      (set_local $chr (call $str.byteAt (get_global $input) (get_local $pos)))
    ))
    (if (i32.and (i32.gt_u (get_local $end) (i32.const 0)) (i32.eqz (get_local $num)))(then
      (call $str.appendBytes (get_local $arg) (i64.extend_u/i32 (get_local $chr)))
    ))
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
    (br 0)
  ))
  (get_local $arg)
)