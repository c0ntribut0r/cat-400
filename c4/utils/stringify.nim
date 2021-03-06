
template strMethod*(T: typedesc, fields: bool = true) =
  ## Defines ``$`` method for selected type ``T``. Output contains type name and all fields' values.
  ##
  ## Args:
  ##   fields - whether to output fields of T
  method `$`*(self: ref T): string = $(T) & (if fields: " " & $self[] else: "")
