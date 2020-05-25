import {
  TEXT_AREA,
  TEXT_FIELD,
  NUMERIC_FIELD,
  TICK_FIELD
} from "../../../../../form";

import { textFieldForm, tickboxFieldForm } from "./forms";

export const getFormField = (field, i18n) => {
  const type = field.get("type");
  const name = field.get("name");

  switch (type) {
    case TEXT_FIELD:
    case TEXT_AREA:
    case NUMERIC_FIELD:
      return textFieldForm(name, i18n);
    case TICK_FIELD:
      return tickboxFieldForm(name, i18n);
    default:
      return textFieldForm(name, i18n);
  }
};

export const addWithIndex = (arr, index, newItem) => [
  ...arr.slice(0, index),

  newItem,

  ...arr.slice(index)
];
