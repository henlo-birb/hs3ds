#!/usr/bin/python
from PIL import Image
import os
import argparse
import json
from math import sqrt


parser = argparse.ArgumentParser(
    description="convert gif to simple texture atlas")
parser.add_argument("filename")
parser.add_argument("-d", help="data output file")
parser.add_argument("-j", action = "store_true", help="just generate data, not atlases")
parser.add_argument("-s", type=int, help="percentage scale factor")
parser.add_argument("-dir", action = "store_true")

args = parser.parse_args()
anim_name = args.filename.replace(".gif", "")


output_data = {}
if args.d and os.path.exists(args.d):
    with open(args.d) as f:
        output_data = json.load(f)
        if (type(output_data) == list):
            raise("data file must be a dictionary/object")
data_file = args.d or anim_name + ".json"


cols = 3
rows = 4
scale = args.s or 50

with Image.open(args.filename) as im:
    w = int(im.width * scale / 100)
    h = int(im.height * scale / 100)
    counter = 0
    atlases = []
    data = {
        "nFrames": im.n_frames,
        "width": w,
        "height": h,
        "cols": cols,
        "rows": rows,
        "durations": [],
        "atlasWidth": w * cols,
        "atlasHeight": h * rows
    }
    for i in range(im.n_frames):
        if counter == 0:
            atlases.append(Image.new("RGB", (w * cols, h * rows))) # create new atlas if needed

        im.seek(i) # go to next frame

        data["durations"].append(im.info["duration"]) # update duration info

        frame = Image.new("RGB", (im.width, im.height)) # create image to use for scaling
        frame.paste(im) # paste current frame to scalable copy
        frame.thumbnail((w, h), Image.ANTIALIAS) # scale the frame

        atlases[-1].paste(frame, (counter % cols * w, counter // cols * h)) # paste into current atlas
        counter += 1 # increment counter
        counter %= cols * rows # reset counter if needed
    data["nAtlases"] = len(atlases)
    output_data[anim_name] = data
    with open(data_file, 'w') as f:
        json.dump(output_data, f)

    pil_output = anim_name + ".png"
    if not args.j:
        for i, atl in enumerate(atlases):
            atl.save(pil_output) # save atlas to png
            cmd = f"tex3ds {pil_output} -o {args.filename.replace('.gif', f'_{i + 1}.t3x')}" # generate t3x file, 1 indexed because lua is stupid
            os.system(cmd)
        os.system(f"rm {pil_output}") 
