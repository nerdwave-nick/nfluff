pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root
    function validateTheme(theme) {
        const errors = [];
        if (theme.colors)
            errors.push(...validateColors(theme.colors));
        if (theme.typography)
            errors.push(...validateTypography(theme.typography));
        if (theme.shapes)
            errors.push(...validateShapes(theme.shapes));
        if (theme.spacing)
            errors.push(...validateSpacing(theme.spacing));
        return errors;
    }

    function validateColors(colors) {
        const errors = [];
        if (colors) {
            if (typeof colors !== "object") {
                errors.push("colors must be an object, is " + typeof colors);
                return errors;
            }
            errors.push(...checkColor("primary", colors.primary));
            errors.push(...checkColor("onPrimary", colors.onPrimary));
            errors.push(...checkColor("primaryContainer", colors.primaryContainer));
            errors.push(...checkColor("onPrimaryContainer", colors.onPrimaryContainer));

            errors.push(...checkColor("secondary", colors.secondary));
            errors.push(...checkColor("onSecondary", colors.onSecondary));
            errors.push(...checkColor("secondaryContainer", colors.secondaryContainer));
            errors.push(...checkColor("onSecondaryContainer", colors.onSecondaryContainer));

            errors.push(...checkColor("tertiary", colors.tertiary));
            errors.push(...checkColor("onTertiary", colors.onTertiary));
            errors.push(...checkColor("tertiaryContainer", colors.tertiaryContainer));
            errors.push(...checkColor("onTertiaryContainer", colors.onTertiaryContainer));

            errors.push(...checkColor("error", colors.error));
            errors.push(...checkColor("onError", colors.onError));
            errors.push(...checkColor("errorContainer", colors.errorContainer));
            errors.push(...checkColor("onErrorContainer", colors.onErrorContainer));

            errors.push(...checkColor("background", colors.background));
            errors.push(...checkColor("onBackground", colors.onBackground));

            errors.push(...checkColor("surface", colors.surface));
            errors.push(...checkColor("onSurface", colors.onSurface));
            errors.push(...checkColor("surfaceVariant", colors.surfaceVariant));
            errors.push(...checkColor("onSurfaceVariant", colors.onSurfaceVariant));

            errors.push(...checkColor("outline", colors.outline));
            errors.push(...checkColor("shadow", colors.shadow));
        }
        return errors;
    }

    readonly property var colorMatchRegex: /#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})?/i
    function checkColor(property, value) {
        if (value) {
            if (typeof value !== "string") {
                return [`${property}: ${value} is not a string`];
            }
            if (value.length !== 7 && value.length !== 9 && !colorMatchRegex.test(value)) {
                return [`${property}: ${value} is not a valid #rrggbb[aa] hex color`];
            }
        }
        return [];
    }

    function tryParseColor(str) {
        if (str === undefined || str === "")
            return undefined;
        var len = str.length;
        let color = Qt.color(str);
        if (str.length === 9) {
            color = Qt.rgba(color.a, color.r, color.g, color.b);
        }
        return color;
    }

    function validateTypography(typography) {
        const errors = [];
        if (typeof typography !== "object") {
            errors.push("typography must be an object");
            return errors;
        }
        if (typography) {
            if (typography.fontFamily) {
                if (typeof typography.fontFamily !== "string") {
                    errors.push("typography.fontFamily must be a string");
                } else if (Qt.fontFamilies().indexOf(typography.fontFamily) === -1) {
                    errors.push(`font family "${typography.fontFamily}" is not installed`);
                }
            }
            const large = typography.large;
            if (large) {
                if (typeof large !== "object") {
                    errors.push("typography.large must be an object");
                    return errors;
                }
                if (large.size) {
                    if (typeof large.size !== "number") {
                        errors.push("typography.large.size must be a number");
                    }
                }
                if (large.weight) {
                    if (typeof large.weight !== "number") {
                        errors.push("typography.large.weight must be a number");
                    }
                }
            }
            const medium = typography.medium;
            if (medium) {
                if (typeof medium !== "object") {
                    errors.push("typography.medium must be an object");
                    return errors;
                }
                if (medium.size) {
                    if (typeof medium.size !== "number") {
                        errors.push("typography.medium.size must be a number");
                    }
                }
                if (medium.weight) {
                    if (typeof medium.weight !== "number") {
                        errors.push("typography.medium.weight must be a number");
                    }
                }
            }
            const small = typography.small;
            if (small) {
                if (typeof small !== "object") {
                    errors.push("typography.small must be an object");
                    return errors;
                }
                if (small.size) {
                    if (typeof small.size !== "number") {
                        errors.push("typography.small.size must be a number");
                    }
                }
                if (small.weight) {
                    if (typeof small.weight !== "number") {
                        errors.push("typography.small.weight must be a number");
                    }
                }
            }
        }
        return errors;
    }

    function validateShapes(shapes) {
        const errors = [];
        if (typeof shapes !== "object") {
            errors.push("shapes must be an object");
            return errors;
        }
        if (shapes) {
            if (shapes.cornerSmall) {
                if (typeof shapes.cornerSmall !== "number") {
                    errors.push("shapes.cornerSmall must be a number");
                }
            }
            if (shapes.cornerMedium) {
                if (typeof shapes.cornerMedium !== "number") {
                    errors.push("shapes.cornerMedium must be a number");
                }
            }
            if (shapes.cornerLarge) {
                if (typeof shapes.cornerLarge !== "number") {
                    errors.push("shapes.cornerLarge must be a number");
                }
            }
        }
        return errors;
    }

    function validateSpacing(spacing) {
        const errors = [];
        if (typeof spacing !== "object") {
            errors.push("spacing must be an object");
            return errors;
        }
        if (spacing) {
            if (spacing.sm) {
                if (typeof spacing.sm !== "number") {
                    errors.push("spacing.sm must be a number");
                }
            }
            if (spacing.md) {
                if (typeof spacing.md !== "number") {
                    errors.push("spacing.md must be a number");
                }
            }
            if (spacing.lg) {
                if (typeof spacing.lg !== "number") {
                    errors.push("spacing.lg must be a number");
                }
            }
        }
        return errors;
    }
}
