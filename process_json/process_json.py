#!/usr/bin/python3.10
import json
import luadata
import re
import os
from bs4 import BeautifulSoup
from pprint import pprint
import progressbar

data = {}

with open("mspa.json", "r") as f:
    data = json.load(f)

hs_filtered = {
    k: v for k, v in data["story"].items() if any("hs2" in m for m in v["media"])
}

conv_key = lambda k: k if not k.isdigit() else int(k) - 1900


def get_color(style):
    if "color" in style:
        h = style.split("color: ")[1]
        try:
            match h:
                case "red":
                    return [1, 0, 0]
                case "blue":
                    return [0, 0, 1]
                case "green":
                    return [0, 1, 0]
                case "white":
                    return [1, 1, 1]
                case "black":
                    return [0, 0, 0]
                case _:
                    return [int(h[i : i + 2], 16) / 255.0 for i in (1, 3, 5)]
        except:
            print(h)
    return [0, 0, 0]

def get_lines(s):
    words = re.findall("\S+", s)
    whitespace = re.findall("\s+", s)

    lines = []
    line = ""
    for i, w in enumerate(words):
        if i+1 < len(words):
            if len(line + w + whitespace[i] + words[i+1]) > 38:
                lines.append(line + w + "\n")
                line = ""
            else:
                line += w + whitespace[i]
        else:
            lines.append(line + w)
    if lines:
        lines[-1] += "\n"
    return lines

max_medias = 0

os.system("mkdir -p pages")
bar = progressbar.ProgressBar(max_value=len(hs_filtered.items()), redirect_stdout=True)
for k, v in hs_filtered.items():
    new_content = []
    soup = BeautifulSoup(v["content"], "html.parser")
    underline_spans = ""
    for e in soup.contents:
        match e.name:
            case "br":
                new_content.append([0,0,0])
                new_content.append("\n")
            case "span":
                if e.string:
                    c = get_color(e.attrs["style"])
                    lines = get_lines(e.string)
                    for l in lines:
                        new_content.append(c)
                        new_content.append(l)
                    # if "text-decoration: underline" in e.attrs["style"]:
                    #     e.string = "_ul_" + e.string
            case _:
                s = str(e) if not e.string else e.string
                lines = get_lines(s)
                for l in lines:
                    new_content.append([0, 0, 0])
                    new_content.append(l)
                
    v["content"] = new_content
    v["next"] = [conv_key(n) for n in v["next"]]
    v["media"] = [
            m.replace("/storyfiles/hs2/", "").replace(".gif", "") for m in v["media"]
        ]
    if len(v["media"]) > max_medias:
        max_medias = len(v["media"])
    
    v["page_id"] = conv_key(v["pageId"])
    v["long_title"] = len(v["title"]) > 32
    del(v["pageId"])
    if "previous" in v:
        v["previous"] = conv_key(v["previous"])
        
        
    luadata.write(f"pages/{conv_key(k)}.lua", v, indent="\t")
    bar.value += 1
    bar.update()
print(max_medias)