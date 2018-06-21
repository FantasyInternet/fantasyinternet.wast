fantasyinternet.wast
====================
wast library for making programs for the fantasy internet.

Include these by using [waquire](https://github.com/FantasyInternet/waquire).

    (module
      ;; See API documentation at https://fantasyinternet.github.io/api
      (import "env" "pushFromMemory" (func $pushFromMemory (param $offset i32) (param $length i32)))
      (import "env" "popToMemory" (func $popToMemory (param $offset i32)))
      
      ;;@require $mem "fantasyinternet.wast/memory.wast"
      ;;@require $str "fantasyinternet.wast/strings.wast"
      ;;@require $gfx "fantasyinternet.wast/graphics.wast"

      ;; Table for callback functions.
      (table $table 8 anyfunc)
        (export "table" (table $table))

      ;; Linear memory.
      (memory $memory 1)
        (export "memory" (memory $memory))

    )