function cy --wraps=codex --description 'alias cy=codex --yolo'
    # Through the codex function (which adds --yolo), never `command codex`,
    # so the session gets its own scope in agents.slice.
    codex $argv
end
