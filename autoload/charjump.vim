" TODO: Consider 'selection' option
vim9script

class State
  public var forward: bool
  public var exclusive: bool
  public var char: string

  def newClone(stateAny: any)
    const state: State = stateAny
    this.forward = state.forward
    this.exclusive = state.exclusive
    this.char = state.char
  enddef
endclass

class Jumper
  const _state: State

  def new(state: State)
    this._state = state
  enddef

  def DoJump()
    Jumper._doJump(this._state)
  enddef

  def Repeat(obverse: bool)
    var state = State.newClone(this._state)
    if !obverse
      state.forward = !state.forward
    endif

    const curpos = getcurpos()
    if state.exclusive
      if state.forward
        normal! l
      else
        normal! h
      endif
    endif

    const isTextobj = mode(1) ==# 'no'
    const jumped = Jumper._doJump(state)

    if state.exclusive
      if !jumped
        setpos('.', curpos)
      elseif isTextobj
        if state.forward
          normal! h
        else
          normal! l
        endif
      endif
    endif
  enddef

  # Jump to the given character.  Return true if succesfully jumped.
  static def _doJump(state: State): bool
    if state.char =~# '^\a'
      return Jumper._doJumpWordBoundary(state)
    elseif state.char =~# "^\<C-v>"
      var s = State.newClone(state)
      s.char = s.char[1]
      return Jumper._doJumpAnywhere(s)
    else
      return Jumper._doJumpAnywhere(state)
    endif
  enddef

  # Jump to the given alphabet on word boundary.  Return TRUE if succesfully
  # jumped.
  static def _doJumpWordBoundary(state: State): bool
    const curpos = getcurpos()
    var pattern = Jumper._wordBoundaryAlphabetSearchPattern(state.char)
    const stopline = line('.')
    const flags = state.forward ? '' : 'b'
    for i in range(v:count1)
      if search(pattern, flags, stopline) == 0
        setpos('.', curpos)
        return false
      endif
    endfor
    if state.exclusive
      if state.forward
        normal! h
      else
        normal! l
      endif
    endif
    if mode(1) ==# 'no'
      normal! v
      setpos('.', curpos)
    endif
    return true
  enddef

  # Jump to the given character.  The character doesn't have to be on word
  # boundary.  Return TRUE if succesfully jumped.
  static def _doJumpAnywhere(state: State): bool
    const curpos = getcurpos()
    var operator = state.exclusive ? 't' : 'f'
    if !state.forward
      operator = toupper(operator)
    endif

    execute $'normal! {v:count1}{operator}{state.char}'
    if getcurpos() == curpos
      return false
    endif

    if mode(1) ==# 'no'
      normal! v
      setpos('.', curpos)
    endif
    return true
  enddef

  static def _wordBoundaryAlphabetSearchPattern(char: string): string
    var pats: list<string>
    if char =~# '\l'
      const upper = toupper(char)
      const lower = tolower(char)
      pats = [
        $'%(^|<|\A)@<=[{upper}{lower}]',  # snake_case
        $'[{upper}{lower}]%(>|\A|$)@=',  # snake_case
        $'{lower}\u@=',  # CamelCase
        $'\l@<={upper}',  # CamelCase
      ]
    else  # Upper-cased alphabet
      pats = [
        $'%(^|<|\A|\l)@<={char}',
        $'{char}%(>|\A|$)@='
      ]
    endif
    return $'\C\v%({join(pats, '|')})'
  enddef
endclass

var jumper: Jumper

export def Jump(forward: bool, exclusive: bool): string
  var char = getcharstr()
  if char ==# "\<ESC>"
    return ''
  elseif char ==# "\<C-k>"  # Support digraph
    for _ in range(2)
      const graph = getcharstr()
      if graph ==# "\<ESC>"  # Cancel
        return ''
      endif
      char ..= graph
    endfor
  elseif char ==# "\<C-v>"
    const graph = getcharstr()
    if graph ==# "\<ESC>"  # Cancel
      return ''
    endif
    char ..= graph
  endif
  jumper = Jumper.new(State.new(forward, exclusive, char))
  return $"\<Cmd>call {expand('<SID>')}InvokeJump()\<CR>"  # Trick to make this dot-repeatable
enddef

export def Repeat(obverse: bool)
  if jumper != null_object
    jumper.Repeat(obverse)
  endif
enddef

def InvokeJump()
  if jumper != null_object
    jumper.DoJump()
  endif
enddef
