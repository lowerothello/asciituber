#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <ctype.h>

#define STR_LEN 1024

struct S {
	int X;
	int Y;
	int H;
	int W;
	int MODX;
	int MODY;
	char path[STR_LEN];
	char buffer[STR_LEN];
	int row;
	int col;
	int filmheight;
	int frame;
} s;

int min(int a, int b) {
	return (a > b) ? b : a;
}

int linecount(char* filename, char* buffer) {
	FILE *fp = fopen(filename, "r");
	if (fp == NULL) {
		printf("Failed to open file %s for reading\n", filename);
		return 1;
	}

	int lc = 0;
	while (fgets(buffer, STR_LEN, fp))
		lc++;

	fclose(fp);

	return lc;
}

void drawlayer (struct S s) {
	FILE *layer = fopen(s.path, "r");
	if (layer == NULL) {
		return;
	}

	int lineno = s.row + s.Y + s.MODY; /* reset lineno */
	int xpos = s.X + s.MODX + s.col;
	int ltrim = 0;
	if (xpos <= 0)
		ltrim = xpos * -1 + 1;

	/* get the film frame count */
	int filmframecount;
	if (s.filmheight > 0) {
		filmframecount = (linecount(s.path, s.buffer) - 5) / s.filmheight;
	} else {
		filmframecount = 1;
	}

	/* read the layer's header */
	fgets(s.buffer, STR_LEN, layer); int fg = atoi(s.buffer);
	fgets(s.buffer, STR_LEN, layer); int bg = atoi(s.buffer);
	fgets(s.buffer, STR_LEN, layer); int attr = atoi(s.buffer);
	fgets(s.buffer, STR_LEN, layer); int filmtime = atoi(s.buffer);
	/* filmshownframe is more complex than the above few */
	int filmshownframe;
	fgets(s.buffer, STR_LEN, layer);
	if (! s.frame || filmtime <= 0)
		filmshownframe = 1;
	else {
		switch (atoi(s.buffer)) {
			case 0: filmshownframe = (min(s.frame, filmframecount * filmtime)) / filmtime;
			case 1: filmshownframe = (s.frame % (filmframecount * filmtime)) / filmtime;
		}
	}

	int drawnlines = 0;
	int processedlines = 0;
	
	int trimwidth;
	int i;
	while (fgets(s.buffer, STR_LEN, layer)) {
		/* burn through lines until the wanted frame is queued */
		processedlines++;
		if (filmshownframe >= 1 && processedlines <= (filmshownframe * s.filmheight)) continue;

		if (lineno >= s.H) break; /* finish before lines are drawn off screen */
		if (lineno >= 1) { /* start when lines are being drawn on screen */
			/* stop after drawing a full frame */
			drawnlines++;
			if (s.filmheight > 0 && drawnlines > s.filmheight) break;

			/* trim off the left side */
			if (ltrim > 0) memmove(s.buffer, s.buffer+ltrim, strlen(s.buffer));
			if (strlen(s.buffer) > 0) {
				/* for trimming off the right side later */
				trimwidth = min(strlen(s.buffer) + ltrim, s.W - s.col - s.MODX);
				/* width mod in case we're trimming off the left side
				magic number 1 is cos the xpos is 0 instead of 1 */
				if (xpos < 0) trimwidth = trimwidth + xpos - 1;

				// set text formatting opts
				printf("\033[%dm\033[38;5;%dm\033[48;5;%dm", attr, fg, bg);
				// draw the block
				for (i = 0; i < min(strlen(s.buffer), trimwidth); i++) {
					if (s.buffer[i] != ' ')
						printf("\033[%d;%dH%c", lineno, xpos + i, s.buffer[i]);
				}
				// unset text formatting opt
				printf("\033[m");
			}
		}
		lineno++;
	}
	fclose(layer);
}

int main(int argc, char *argv[]) {
	if (argv[1] == NULL) {
		printf("Missing args\n");
		return 1;
	}

	char dirpath[STR_LEN];

	/* CONFIG FILE */
	strcpy(s.path, argv[1]);
	FILE *config = fopen(strcat(s.path, "/config"), "r");
	if (config == NULL) {
		printf("Failed to open config file\n");
		return 1;
	}

	/* there's always the same amount of fields to read */
	fgets(s.buffer, STR_LEN, config); s.row = atoi(s.buffer);
	fgets(s.buffer, STR_LEN, config); s.col = atoi(s.buffer);
	fgets(s.buffer, STR_LEN, config); s.filmheight = atoi(s.buffer);

	s.X = atoi(getenv("X"));
	s.Y = atoi(getenv("Y"));
	s.H = atoi(getenv("H"));
	s.W = atoi(getenv("W"));
	s.MODX = atoi(getenv("MODX"));
	s.MODY = atoi(getenv("MODY"));

	/* completely off screen checks */
	if (s.row + s.Y + s.MODY > s.H) return 0;
	if (s.col + s.X + s.MODX > s.W) return 0;

	fclose(config);

	/* LAYER FILES */
	s.frame = atoi(argv[2]);
	strcpy(s.path, argv[1]); strcat(s.path, "/0"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/1"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/2"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/3"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/4"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/5"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/6"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/7"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/8"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/9"); drawlayer(s);

	return 0;
}
