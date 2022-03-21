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


os.system("mkdir -p pages")

bar = progressbar.ProgressBar(max_value=len(hs_filtered.items()))
for k, v in hs_filtered.items():
    new_content = []
    soup = BeautifulSoup(v["content"], "html.parser")
    breaks = 0
    underline_spans = ""
    for e in soup.contents:
        match e.name:
            case "br":
                breaks += 1
            case "span":
                if e.string:
                    new_content.append(get_color(e.attrs["style"]))
                    if "text-decoration: underline" in e.attrs["style"]:
                        e.string = "_ul_" + e.string
                    new_content.append("\n" * breaks + e.string)
                    breaks = 0
            case _:
                new_content.append([0, 0, 0])
                if e.string:
                    new_content.append("\n" * breaks + e.string)
                    breaks = 0
                else:
                    new_content.append(str(e))
    v["content"] = new_content
    v["next"] = [conv_key(n) for n in v["next"]]
    if "previous" in v:
        v["previous"] = conv_key(v["previous"])
        v["pageId"] = conv_key(v["pageId"])
        v["media"] = [
            m.replace("/storyfiles/hs2/", "").replace(".gif", "") for m in v["media"]
        ]
    luadata.write(f"pages/{conv_key(k)}.lua", v, indent="\t")
    bar.value += 1
    bar.update()
