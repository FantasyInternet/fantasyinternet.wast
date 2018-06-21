;; Memory management

(data (i32.const 0) "\00\00\00\00\00\00\00\00\10\00\00\00\00\00\00\00")
(global $nextPartId (mut i32) (i32.const 1))
(global $parentPart (mut i32) (i32.const 0))

;; Get offset of partition info
(func $getPartIndex (param $id i32) (result i32)
  (local $indexOffset i32)
  (local $indexLength i32)
  (local $p i32)
  (set_local $indexOffset (i32.const 0x00))
  (set_local $indexLength (i32.const 0x10))
  (set_local $p (get_local $indexOffset))
  (block(loop
    (br_if 1 (i32.ge_u (get_local $p) (i32.add (get_local $indexOffset) (get_local $indexLength))))
    (if (i32.eq (i32.load (get_local $p)) (get_local $id)) (then
      (return (get_local $p))
    ))
    (if (i32.eq (i32.load (get_local $p)) (i32.const 0)) (then
      (set_local $indexOffset (i32.load (i32.add (get_local $p) (i32.const 0x8))))
      (set_local $indexLength (i32.load (i32.add (get_local $p) (i32.const 0xc))))
      (set_local $p (get_local $indexOffset))
    )(else
      (set_local $p (i32.add (get_local $p) (i32.const 0x10)))
    ))
    (br 0)
  ))
  (i32.const -1)
)
;; Get parent of partition
(func $getPartParent (param $id i32) (result i32)
  (local $i i32)
  (set_local $i (call $getPartIndex (get_local $id)))
  (if (i32.ne (get_local $i) (i32.const -1)) (then
    (set_local $i (i32.load (i32.add (get_local $i) (i32.const 0x4))))
  ))
  (get_local $i)
)
;; Get offset of partition
(func $getPartOffset (param $id i32) (result i32)
  (local $i i32)
  (set_local $i (call $getPartIndex (get_local $id)))
  (if (i32.ne (get_local $i) (i32.const -1)) (then
    (set_local $i (i32.load (i32.add (get_local $i) (i32.const 0x8))))
  ))
  (get_local $i)
)
;; Get length of partition
(func $getPartLength (param $id i32) (result i32)
  (local $i i32)
  (set_local $i (call $getPartIndex (get_local $id)))
  (if (i32.ne (get_local $i) (i32.const -1)) (then
    (set_local $i (i32.load (i32.add (get_local $i) (i32.const 0xc))))
  ))
  (get_local $i)
)

;; Get ID of next partition in memory
(func $getNextPart (param $fromOffset i32) (result i32)
  (local $indexOffset i32)
  (local $indexLength i32)
  (local $id i32)
  (local $offset i32)
  (local $bestId i32)
  (local $bestIdOffset i32)
  (local $p i32)
  (set_local $indexOffset (i32.const 0x00))
  (set_local $indexLength (i32.const 0x10))
  (set_local $bestId (i32.const -1))
  (set_local $bestIdOffset (i32.const -1))
  (set_local $p (get_local $indexOffset))
  (block(loop
    (br_if 1 (i32.ge_u (get_local $p) (i32.add (get_local $indexOffset) (get_local $indexLength))))
    (set_local $id (i32.load (get_local $p)))
    (set_local $offset (i32.load (i32.add (get_local $p) (i32.const 0x8))))
    (if (i32.and (i32.ge_u (get_local $offset) (get_local $fromOffset)) (i32.lt_u (get_local $offset) (get_local $bestIdOffset))) (then
      (set_local $bestId (get_local $id))
      (set_local $bestIdOffset (get_local $offset))
    ))
    (if (i32.eq (i32.load (get_local $p)) (i32.const 0)) (then
      (set_local $indexOffset (i32.load (i32.add (get_local $p) (i32.const 0x8))))
      (set_local $indexLength (i32.load (i32.add (get_local $p) (i32.const 0xc))))
      (set_local $p (get_local $indexOffset))
    )(else
      (set_local $p (i32.add (get_local $p) (i32.const 0x10)))
    ))
    (br 0)
  ))
  (get_local $bestId)
)

;; Allocate space in memory and return offset
(func $alloc (param $len i32) (result i32)
  (local $offset i32)
  (local $nextId i32)
  (local $nextOffset i32)
  (set_local $offset (i32.const 0x10))
  (block(loop
    (set_local $nextId (call $getNextPart (get_local $offset)))
    (if (i32.eq (get_local $nextId) (i32.const -1))(then
      (set_local $nextOffset (i32.mul (current_memory) (i32.const 65536)))
    )(else
      (set_local $nextOffset (call $getPartOffset (get_local $nextId)))
    ))
    (br_if 1 (i32.gt_u (i32.sub (get_local $nextOffset) (get_local $offset)) (get_local $len)))
    (br_if 1 (i32.eq (get_local $nextId) (i32.const -1)))
    (set_local $offset (i32.add (get_local $nextOffset) (i32.add (call $getPartLength (get_local $nextId)) (i32.const 1))))
    (br 0)
  ))
  (if (i32.le_u (i32.sub (get_local $nextOffset) (get_local $offset)) (get_local $len)) (then
    (if (i32.lt_s (grow_memory (i32.add (i32.div_u (get_local $len) (i32.const 65536)) (i32.const 1))) (i32.const 0)) (then
      (unreachable)
    ))
    (set_local $offset (call $alloc (get_local $len)))
  ))
  (get_local $offset)
)
;; Resize partition
(func $resizePart (param $id i32) (param $newlen i32)
  (local $offset i32)
  (local $len i32)
  (set_local $offset (call $getPartOffset (get_local $id)))
  (set_local $len (call $getPartLength (get_local $id)))
  (if (i32.le_u (get_local $newlen) (get_local $len)) (then
    (i32.store (i32.add (call $getPartIndex (get_local $id)) (i32.const 0xc)) (get_local $newlen))
  )(else
    (i32.store (i32.add (call $getPartIndex (get_local $id)) (i32.const 0x8)) (call $alloc (get_local $newlen)))
    (i32.store (i32.add (call $getPartIndex (get_local $id)) (i32.const 0xc)) (get_local $newlen))
    (call $copyMem (get_local $offset) (call $getPartOffset (get_local $id)) (get_local $len))
  ))
)
;; Copy chunk of memory 
(func $copyMem (param $fromOffset i32) (param $toOffset i32) (param $len i32)
  (local $delta i32)
  (if (i32.eqz (get_local $len)) (return))
  (if (i32.gt_u (get_local $fromOffset) (get_local $toOffset)) (then
    (set_local $delta (i32.const 1))
  )(else
    (set_local $delta (i32.const -1))
    (set_local $len (i32.sub (get_local $len) (i32.const 1)))
    (set_local $fromOffset (i32.add (get_local $fromOffset) (get_local $len)))
    (set_local $toOffset   (i32.add (get_local $toOffset  ) (get_local $len)))
    (set_local $len (i32.add (get_local $len) (i32.const 1)))
  ))
  (block (loop
    (br_if 1 (i32.eqz (get_local $len)))
    (i32.store8 (get_local $toOffset) (i32.load8_u (get_local $fromOffset)))
    (set_local $fromOffset (i32.add (get_local $fromOffset) (get_local $delta)))
    (set_local $toOffset   (i32.add (get_local $toOffset  ) (get_local $delta)))
    (set_local $len        (i32.sub (get_local $len)        (i32.const 1)))
    (br 0)
  ))
)
;; Create partition
(func $createPart (param $len i32) (result i32)
  (local $offset i32)
  (call $resizePart (i32.const 0) (i32.add (call $getPartLength (i32.const 0)) (i32.const 0x10)))
  (set_local $offset (i32.sub (i32.add (call $getPartOffset (i32.const 0)) (call $getPartLength (i32.const 0))) (i32.const 0x10)))
  (i32.store (i32.add (get_local $offset) (i32.const 0x0)) (get_global $nextPartId))
  (i32.store (i32.add (get_local $offset) (i32.const 0x4)) (get_global $parentPart))
  (i32.store (i32.add (get_local $offset) (i32.const 0x8)) (call $alloc (get_local $len)))
  (i32.store (i32.add (get_local $offset) (i32.const 0xc)) (get_local $len))
  (get_global $nextPartId)
  (set_global $nextPartId (i32.add (get_global $nextPartId) (i32.const 1)))
)

;; Delete partition
(func $deletePart (param $id i32)
  (local $indexOffset i32)
  (local $indexLength i32)
  (local $p i32)
  (set_local $indexOffset (call $getPartOffset (i32.const 0)))
  (set_local $indexLength (call $getPartLength (i32.const 0)))
  (set_local $p (get_local $indexOffset))
  (block(loop
    (br_if 1 (i32.ge_u (get_local $p) (i32.add (get_local $indexOffset) (get_local $indexLength))))
    (if (i32.eq (i32.load (get_local $p)) (get_local $id)) (then
      (call $copyMem (i32.sub (i32.add (get_local $indexOffset) (get_local $indexLength)) (i32.const 0x10)) (get_local $p) (i32.const 0x10))
      (set_local $indexLength (i32.sub (get_local $indexLength) (i32.const 0x10)))
      (call $resizePart (i32.const 0) (get_local $indexLength))
      (set_local $p (i32.sub (get_local $p) (i32.const 0x10)))
    ))
    (if (i32.eq (i32.load (i32.add (get_local $p) (i32.const 0x4))) (get_local $id)) (then
      (call $deletePart (i32.load (get_local $p)))
      (set_local $indexOffset (call $getPartOffset (i32.const 0)))
      (set_local $indexLength (call $getPartLength (i32.const 0)))
      (set_local $p (i32.sub (get_local $indexOffset) (i32.const 0x10)))
    ))
    (set_local $p (i32.add (get_local $p) (i32.const 0x10)))
    (br 0)
  ))
  (if (i32.eq (get_global $parentPart) (get_local $id))(then
    (call $exitPart)
  ))
)
;; Move partition to parent
(func $movePartUp (param $id i32)
  (local $p i32)
  (set_local $p (call $getPartIndex (get_local $id)))
  (i32.store (i32.add (get_local $p) (i32.const 0x4)) (call $getPartParent (call $getPartParent (get_local $id))))
)
;; Enter partition. All partitions created from this point will have this partition as parent.
(func $enterPart (param $id i32)
  (set_global $parentPart (get_local $id))
)
;; Exit partition and goto its parent.
(func $exitPart
  (set_global $parentPart (call $getPartParent (get_global $parentPart)))
)
;; Delete currently entered partition and goto parent.
(func $deleteParent
  (call $deletePart (get_global $parentPart))
)
