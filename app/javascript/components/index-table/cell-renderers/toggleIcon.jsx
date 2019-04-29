import React from "react";
import IconButton from "@material-ui/core/IconButton";
import PhotoIcon from "@material-ui/icons/PhotoCamera";
import FlagIcon from "@material-ui/icons/Flag";
import isEmpty from "lodash/isEmpty";

const ToggleIconCell = ({ value, icon }) => (
  <IconButton disabled={isEmpty(value)} color="primary">
    {
      {
        photo: <PhotoIcon />,
        flag: <FlagIcon />
      }[icon]
    }
  </IconButton>
);

export default ToggleIconCell;
