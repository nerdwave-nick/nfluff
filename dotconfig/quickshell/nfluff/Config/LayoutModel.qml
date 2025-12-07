// pragma ComponentBehavior: Bound

// import QtQuick
// import qs.Config

// QtObject {
//     property LayoutModel defaults

//     property int minWidth: defaults.minWidth
//     property int maxWidth: defaults.maxWidth
//     property int height: defaults.height
//     property bool fullWidth: defaults.fullWidth
//     property bool autohide: defaults.autohide

//     // "minWidth": 840,
//     // "maxWidth": 1600,
//     // "height": 50,
//     // "modules": {
//     //     "left": [
//     //         {
//     //             "type": "workspaces",
//     //             "config": {
//     //                 "format": "{name}"
//     //             }
//     //         }
//     //     ],
//     //     "center": [
//     //         {
//     //             "type": "workspace-windows",
//     //             "config": {
//     //                 "format": "{name}"
//     //             }
//     //         }
//     //     ],
//     //     "right": [
//     //         {
//     //             "type": "clock",
//     //             "config": {
//     //                 "format": "hh:mm"
//     //             }
//     //         }
//     //     ]
//     // }


//     function assign(theme) {
//         console.debug("ThemeModel: assigning theme");
//         if (!theme) {
//             console.debug("ThemeModel: assigning default theme");
//             colors_primary = defaults.colors_primary;
//             colors_onPrimary = defaults.colors_onPrimary;
//             colors_primaryContainer = defaults.colors_primaryContainer;
//             colors_onPrimaryContainer = defaults.colors_onPrimaryContainer;
//             colors_secondary = defaults.colors_secondary;
//             colors_onSecondary = defaults.colors_onSecondary;
//             colors_secondaryContainer = defaults.colors_secondaryContainer;
//             colors_onSecondaryContainer = defaults.colors_onSecondaryContainer;
//             colors_tertiary = defaults.colors_tertiary;
//             colors_onTertiary = defaults.colors_onTertiary;
//             colors_tertiaryContainer = defaults.colors_tertiaryContainer;
//             colors_onTertiaryContainer = defaults.colors_onTertiaryContainer;
//             colors_error = defaults.colors_error;
//             colors_onError = defaults.colors_onError;
//             colors_errorContainer = defaults.colors_errorContainer;
//             colors_onErrorContainer = defaults.colors_onErrorContainer;
//             colors_background = defaults.colors_background;
//             colors_onBackground = defaults.colors_onBackground;
//             colors_surface = defaults.colors_surface;
//             colors_onSurface = defaults.colors_onSurface;
//             colors_surfaceVariant = defaults.colors_surfaceVariant;
//             colors_onSurfaceVariant = defaults.colors_onSurfaceVariant;
//             colors_outline = defaults.colors_outline;
//             colors_shadow = defaults.colors_shadow;

//             typography_fontFamily = defaults.typography_fontFamily;
//             typography_largeSize = defaults.typography_largeSize;
//             typography_largeWeight = defaults.typography_largeWeight;
//             typography_mediumSize = defaults.typography_mediumSize;
//             typography_mediumWeight = defaults.typography_mediumWeight;
//             typography_smallSize = defaults.typography_smallSize;
//             typography_smallWeight = defaults.typography_smallWeight;

//             shapes_cornerSmall = defaults.shapes_cornerSmall;
//             shapes_cornerMedium = defaults.shapes_cornerMedium;
//             shapes_cornerLarge = defaults.shapes_cornerLarge;

//             spacing_sm = defaults.spacing_sm;
//             spacing_md = defaults.spacing_md;
//             spacing_lg = defaults.spacing_lg;
//         }

//         if (theme.colors) {
//             console.debug("ThemeModel: assigning colors", theme.colors);
//             colors_primary = ThemeHelper.tryParseColor(theme.colors.primary) ?? defaults.colors_primary;
//             colors_onPrimary = ThemeHelper.tryParseColor(theme.colors.onPrimary) ?? defaults.colors_onPrimary;
//             colors_primaryContainer = ThemeHelper.tryParseColor(theme.colors.primaryContainer) ?? defaults.colors_primaryContainer;
//             colors_onPrimaryContainer = ThemeHelper.tryParseColor(theme.colors.onPrimaryContainer) ?? defaults.colors_onPrimaryContainer;
//             colors_secondary = ThemeHelper.tryParseColor(theme.colors.secondary) ?? defaults.colors_secondary;
//             colors_onSecondary = ThemeHelper.tryParseColor(theme.colors.onSecondary) ?? defaults.colors_onSecondary;
//             colors_secondaryContainer = ThemeHelper.tryParseColor(theme.colors.secondaryContainer) ?? defaults.colors_secondaryContainer;
//             colors_onSecondaryContainer = ThemeHelper.tryParseColor(theme.colors.onSecondaryContainer) ?? defaults.colors_onSecondaryContainer;
//             colors_tertiary = ThemeHelper.tryParseColor(theme.colors.tertiary) ?? defaults.colors_tertiary;
//             colors_onTertiary = ThemeHelper.tryParseColor(theme.colors.onTertiary) ?? defaults.colors_onTertiary;
//             colors_tertiaryContainer = ThemeHelper.tryParseColor(theme.colors.tertiaryContainer) ?? defaults.colors_tertiaryContainer;
//             colors_onTertiaryContainer = ThemeHelper.tryParseColor(theme.colors.onTertiaryContainer) ?? defaults.colors_onTertiaryContainer;
//             colors_error = ThemeHelper.tryParseColor(theme.colors.error) ?? defaults.colors_error;
//             colors_onError = ThemeHelper.tryParseColor(theme.colors.onError) ?? defaults.colors_onError;
//             colors_errorContainer = ThemeHelper.tryParseColor(theme.colors.errorContainer) ?? defaults.colors_errorContainer;
//             colors_onErrorContainer = ThemeHelper.tryParseColor(theme.colors.onErrorContainer) ?? defaults.colors_onErrorContainer;
//             colors_background = ThemeHelper.tryParseColor(theme.colors.background) ?? defaults.colors_background;
//             colors_onBackground = ThemeHelper.tryParseColor(theme.colors.onBackground) ?? defaults.colors_onBackground;
//             colors_surface = ThemeHelper.tryParseColor(theme.colors.surface) ?? defaults.colors_surface;
//             colors_onSurface = ThemeHelper.tryParseColor(theme.colors.onSurface) ?? defaults.colors_onSurface;
//             colors_surfaceVariant = ThemeHelper.tryParseColor(theme.colors.surfaceVariant) ?? defaults.colors_surfaceVariant;
//             colors_onSurfaceVariant = ThemeHelper.tryParseColor(theme.colors.onSurfaceVariant) ?? defaults.colors_onSurfaceVariant;
//             colors_outline = ThemeHelper.tryParseColor(theme.colors.outline) ?? defaults.colors_outline;
//             colors_shadow = ThemeHelper.tryParseColor(theme.colors.shadow) ?? defaults.colors_shadow;
//         }

//         if (theme.typography) {
//             typography_fontFamily = theme.typography.fontFamily ?? defaults.typography_fontFamily;
//             if (theme.typography.large) {
//                 typography_largeSize = theme.typography.large.size ?? defaults.typography_largeSize;
//                 typography_largeWeight = theme.typography.large.weight ?? defaults.typography_largeWeight;
//             } else {
//                 typography_largeSize = defaults.typography_largeSize;
//                 typography_largeWeight = defaults.typography_largeWeight;
//             }
//             if (theme.typography.medium) {
//                 typography_mediumSize = theme.typography.medium.size ?? defaults.typography_mediumSize;
//                 typography_mediumWeight = theme.typography.medium.weight ?? defaults.typography_mediumWeight;
//             } else {
//                 typography_mediumSize = defaults.typography_mediumSize;
//                 typography_mediumWeight = defaults.typography_mediumWeight;
//             }
//             if (theme.typography.small) {
//                 typography_smallSize = theme.typography.small.size ?? defaults.typography_smallSize;
//                 typography_smallWeight = theme.typography.small.weight ?? defaults.typography_smallWeight;
//             } else {
//                 typography_smallSize = defaults.typography_smallSize;
//                 typography_smallWeight = defaults.typography_smallWeight;
//             }
//         } else {
//             typography_fontFamily = defaults.typography_fontFamily;
//             typography_largeSize = defaults.typography_largeSize;
//             typography_largeWeight = defaults.typography_largeWeight;
//             typography_mediumSize = defaults.typography_mediumSize;
//             typography_mediumWeight = defaults.typography_mediumWeight;
//             typography_smallSize = defaults.typography_smallSize;
//             typography_smallWeight = defaults.typography_smallWeight;
//         }

//         // Shapes
//         if (theme.shapes) {
//             shapes_cornerSmall = theme.shapes.cornerSmall ?? defaults.shapes_cornerSmall;
//             shapes_cornerMedium = theme.shapes.cornerMedium ?? defaults.shapes_cornerMedium;
//             shapes_cornerLarge = theme.shapes.cornerLarge ?? defaults.shapes_cornerLarge;
//         } else {
//             shapes_cornerSmall = defaults.shapes_cornerSmall;
//             shapes_cornerMedium = defaults.shapes_cornerMedium;
//             shapes_cornerLarge = defaults.shapes_cornerLarge;
//         }

//         if (theme.spacing) {
//             spacing_sm = theme.spacing.sm ?? defaults.spacing_sm;
//             spacing_md = theme.spacing.md ?? defaults.spacing_md;
//             spacing_lg = theme.spacing.lg ?? defaults.spacing_lg;
//         } else {
//             spacing_sm = defaults.spacing_sm;
//             spacing_md = defaults.spacing_md;
//             spacing_lg = defaults.spacing_lg;
//         }
//     }
// }
