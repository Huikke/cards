import xml.etree.ElementTree as ET
import copy

with open("blueprint.svg") as svg_file:
    tree = ET.parse(svg_file)

root = tree.getroot()
ET.register_namespace("", "http://www.w3.org/2000/svg")
ET.register_namespace("inkscape", "http://www.inkscape.org/namespaces/inkscape")
ET.register_namespace("sodibodi", "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd")
ET.register_namespace("xlink", "http://www.w3.org/1999/xlink")


middle = ["suit1"]
middle_v = ["suit2", "suit3"]
middle_v2 = ["suit14", "suit15"]
middle_h = ["suit8", "suit9"]
middle_h2 = ["suit10", "suit11", "suit12", "suit13"]
corners = ["suit4", "suit5", "suit6", "suit7"]
suit_big = ["suit_big"]
text_big = ["text_big"]

correspondent = {
    1: "A",
    11: "J",
    12: "Q",
    13: "K"
}

suits = ["spade", "heart", "club", "diamond"]

values = {
    1: suit_big,
    2: middle_v,
    3: middle_v + middle,
    4: corners,
    5: corners + middle,
    6: corners + middle_h,
    7: corners + middle_h + middle,
    8: corners + middle_h2,
    9: corners + middle_h2 + middle,
    10: corners + middle_v2 + middle_h2,
    11: text_big,
    12: text_big,
    13: text_big,
}

def make_card(value, suit):
    root_inst = copy.deepcopy(root)
    file_name = "low_ball.svg"
    for g in root_inst.findall("g"):
        label = g.get(() + "label")
        match label:
            case "base":
                pass
            case "helper":
                root_inst.remove(g)
            case "suit":
                for e in g:
                    if e.get("id") == suit:
                        d = e.get("d")
                        for style_part in e.get("style").split(";"):
                            if "fill:#" in style_part:
                                color = style_part
                root_inst.remove(g)
            case "body":
                for e in list(g):
                    label2 = e.get("label")
                    if label2 not in values[value]:
                        g.remove(e)
                if value > 10:
                    center_letter = g.find("text")
                    center_letter.text = correspondent[value]
                    center_letter.set("style", style_edit(center_letter, color))
            case "sides":
                letter_corner = g.find("text")
                if value > 10 or value == 1:
                    letter_corner.text = correspondent[value]
                else:
                    letter_corner.text = str(value)
                letter_corner.set("style", style_edit(letter_corner, color))
            case "blueprint": # Has to be lower to suit in svg
                g[0].set("d", d)
                g[0].set("style", style_edit(g[0], color))

        file_name = (f"{value}_{suit}.svg")
        with open(file_name, "w") as svg_file:
            svg_file.write(ET.tostring(root_inst, encoding="unicode", xml_declaration=True))

# Split style, change color, and join them back
# This took forever
def style_edit(e, color):
    style = e.get("style").split(";")
    for i, style_part in enumerate(style):
        if "fill:#" in style_part:
            style[i] = color
            style = ";".join(style)
            return style

if __name__ == "__main__":
    #make_card(13, "heart")
    for value in values:
        for suit in suits:
            make_card(value, suit)