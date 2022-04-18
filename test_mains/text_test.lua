content1 = {{1,1,1}, [[The problem is that when the subject of troll romance is broached, our sparing human intellects instantly assume the most ingratiating posture of surrender imaginable.

But we will do our best to understand regardless.

Humans have only one form of romance. And though we consider it a complicated subject, spanning a wide range of emotions, social conventions, and implications for reproduction, it is ultimately a superficial slice of what trolls consider the full body of romantic experience. Our concept of romance, in spite of its capacity to fill our art and literature and to rule our individual destinies like little else, is still just that. A single, linear concept. A concept usually denoted by a single symbol.

<3

Troll romance is more complicated than that. Troll romance needs four symbols.

Their understanding of romance is divided into halves, and halved again, producing four quadrants: the FLUSHED QUADRANT, the CALIGINOUS QUADRANT, the PALE QUADRANT, and the ASHEN QUADRANT.

Each quadrant is grouped by the half they share, whether horizontally or vertically, depending on the overlapping properties one examines. The sharpest dichotomy, from an emotional perspective, is drawn between RED ROMANCE and BLACK ROMANCE.

RED ROMANCE, comprised of the flushed and pale quadrants, is a form of romance rooted in strongly positive emotions. BLACK ROMANCE, with its caliginous and ashen quadrants, is rooted in the strongly negative.

On the other hand, the vertical bifurcation has to do with the purpose of the relationship, regardless of the emotions behind it. Those quadrants which are CONCUPISCENT, the flushed and caliginous, have to do with facilitating the elaborate reproductive cycle of trolls. Those which are CONCILIATORY, the pale and ashen, would be more closely likened to platonic relationships by human standards.

There are many parallels between human relationships and the various facets of troll romance. Humans have words to describe relationships of a negative nature, or of a platonic nature. The difference is, for humans, those relationships would never be conceptually grouped with romance. Establishing those sort of relationships for humans is not driven by the same primal forces that drive our tendency to couple romantically. But for trolls, those primal forces involve themselves in the full palette of these relationships, red or black, torrid or friendly. Trolls typically feel strongly compelled to find balance in each quadrant, and seek gratifying relationships that each describes.

The challenge is particularly tortuous for young trolls, who must reconcile the wide range of contradictory emotions associated with this matrix, while understanding the nature of their various romantic urges for the first time.

Of course, young humans have this challenge too. But for trolls, the challenge is fourfold.]]}

content2 = "yees"
content = content1

courier = love.graphics.newFont("courier.bcfnt")

y = 0
add = 0
width = love.graphics.getWidth("left")

function love.draw(screen) 
    if screen ~= "bottom" then
        love.graphics.printf(content, 11, 11 + y, width, "center")
    end
end


function love.gamepadpressed(_, button) 
    if button == "start" then
        love.event.quit()
    end
    if button == "a" then
        if content == content2 then
            content = content1
        else
            content = content2
        end
    end
    if button == "dpup" then add = -1 end
    if button == "dpdown" then add = 1 end
end

function love.gamepadreleased(_, button)
    add = 0
end

function love.update(dt)
    y = y + add
end