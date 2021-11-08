#!/bin/bash

IP=$(ip r | grep /24 | head -n 1 | awk '{print $3}')

